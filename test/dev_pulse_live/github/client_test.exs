defmodule DevPulseLive.Github.ClientTest do
  use ExUnit.Case, async: true

  alias DevPulseLive.Github.Client

  @stub_name DevPulseLive.Github.Client

  defp push_item(overrides \\ %{}) do
    Map.merge(
      %{
        "type" => "PushEvent",
        "repo" => %{"name" => "owner/repo"},
        "actor" => %{"login" => "testuser"},
        "payload" => %{
          "commits" => [
            %{"message" => "fix: something\n\nmore details", "sha" => "abc123"}
          ]
        }
      },
      overrides
    )
  end

  defp pr_item(action \\ "opened") do
    %{
      "type" => "PullRequestEvent",
      "repo" => %{"name" => "owner/repo"},
      "actor" => %{"login" => "testuser"},
      "payload" => %{
        "action" => action,
        "pull_request" => %{
          "title" => "feat: new feature",
          "html_url" => "https://github.com/owner/repo/pull/1"
        }
      }
    }
  end

  defp issue_item(action \\ "opened") do
    %{
      "type" => "IssuesEvent",
      "repo" => %{"name" => "owner/repo"},
      "actor" => %{"login" => "testuser"},
      "payload" => %{
        "action" => action,
        "issue" => %{
          "title" => "bug report",
          "html_url" => "https://github.com/owner/repo/issues/1"
        }
      }
    }
  end

  test "returns :not_modified on 304 response" do
    Req.Test.stub(@stub_name, fn conn ->
      Plug.Conn.send_resp(conn, 304, "")
    end)

    assert {:ok, :not_modified} = Client.fetch_events("testuser")
  end

  test "returns events list on 200 with push event" do
    Req.Test.stub(@stub_name, fn conn ->
      conn
      |> Plug.Conn.put_resp_header("etag", "\"abc123\"")
      |> Req.Test.json([push_item()])
    end)

    assert {:ok, events, etag} = Client.fetch_events("testuser")
    assert length(events) == 1
    assert hd(events).event_type == "push"
    assert hd(events).title == "fix: something"
    assert etag == "\"abc123\""
  end

  test "returns events list on 200 with pull_request event" do
    Req.Test.stub(@stub_name, fn conn ->
      Req.Test.json(conn, [pr_item()])
    end)

    assert {:ok, events, _etag} = Client.fetch_events("testuser")
    assert length(events) == 1
    assert hd(events).event_type == "pull_request"
    assert hd(events).action == "opened"
  end

  test "returns events list on 200 with issues event" do
    Req.Test.stub(@stub_name, fn conn ->
      Req.Test.json(conn, [issue_item()])
    end)

    assert {:ok, events, _etag} = Client.fetch_events("testuser")
    assert length(events) == 1
    assert hd(events).event_type == "issues"
    assert hd(events).title == "bug report"
  end

  test "skips unsupported event types" do
    unknown = %{
      "type" => "WatchEvent",
      "repo" => %{"name" => "owner/repo"},
      "actor" => %{"login" => "testuser"},
      "payload" => %{}
    }

    Req.Test.stub(@stub_name, fn conn ->
      Req.Test.json(conn, [push_item(), unknown])
    end)

    assert {:ok, events, _etag} = Client.fetch_events("testuser")
    assert length(events) == 1
  end

  test "skips push event with no commits" do
    no_commits = push_item(%{"payload" => %{"commits" => []}})

    Req.Test.stub(@stub_name, fn conn ->
      Req.Test.json(conn, [no_commits])
    end)

    assert {:ok, [], _etag} = Client.fetch_events("testuser")
  end

  test "returns error on unexpected status" do
    Req.Test.stub(@stub_name, fn conn ->
      Plug.Conn.send_resp(conn, 403, "Forbidden")
    end)

    assert {:error, {:unexpected_status, 403}} = Client.fetch_events("testuser")
  end

  test "returns error on request failure" do
    Req.Test.stub(@stub_name, fn conn ->
      Req.Test.transport_error(conn, :econnrefused)
    end)

    assert {:error, _reason} = Client.fetch_events("testuser")
  end

  test "includes etag header in request when provided" do
    Req.Test.stub(@stub_name, fn conn ->
      assert Plug.Conn.get_req_header(conn, "if-none-match") != []
      Plug.Conn.send_resp(conn, 304, "")
    end)

    assert {:ok, :not_modified} = Client.fetch_events("testuser", "\"prev-etag\"")
  end

  test "returns nil etag when response has none" do
    Req.Test.stub(@stub_name, fn conn ->
      Req.Test.json(conn, [push_item()])
    end)

    assert {:ok, _events, nil} = Client.fetch_events("testuser")
  end
end
