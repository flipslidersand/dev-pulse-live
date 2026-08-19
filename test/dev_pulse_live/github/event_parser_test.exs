defmodule DevPulseLive.Github.EventParserTest do
  use ExUnit.Case, async: true

  alias DevPulseLive.Github.EventParser

  test "parses push event" do
    payload = %{
      "commits" => [
        %{
          "id" => "abc123",
          "message" => "fix: bug\n\ndetails",
          "url" => "https://github.com/owner/repo/commit/abc123"
        }
      ],
      "repository" => %{"full_name" => "owner/repo"},
      "pusher" => %{"name" => "testuser"}
    }

    assert {:ok, attrs} = EventParser.parse("push", payload)
    assert attrs.event_type == "push"
    assert attrs.title == "fix: bug"
    assert attrs.sha == "abc123"
    assert attrs.actor == "testuser"
    assert attrs.repo_name == "owner/repo"
  end

  test "parses pull_request event" do
    payload = %{
      "action" => "opened",
      "pull_request" => %{
        "title" => "feat: new feature",
        "html_url" => "https://github.com/owner/repo/pull/1",
        "user" => %{"login" => "testuser"}
      },
      "repository" => %{"full_name" => "owner/repo"}
    }

    assert {:ok, attrs} = EventParser.parse("pull_request", payload)
    assert attrs.event_type == "pull_request"
    assert attrs.action == "opened"
    assert attrs.title == "feat: new feature"
  end

  test "parses issues event" do
    payload = %{
      "action" => "opened",
      "issue" => %{
        "title" => "bug report",
        "html_url" => "https://github.com/owner/repo/issues/1",
        "user" => %{"login" => "testuser"}
      },
      "repository" => %{"full_name" => "owner/repo"}
    }

    assert {:ok, attrs} = EventParser.parse("issues", payload)
    assert attrs.event_type == "issues"
    assert attrs.title == "bug report"
  end

  test "returns error for unsupported event" do
    assert {:error, {:unsupported_event, "star"}} = EventParser.parse("star", %{})
  end

  test "returns error for push with no commits" do
    payload = %{
      "commits" => [],
      "repository" => %{"full_name" => "owner/repo"},
      "pusher" => %{"name" => "testuser"}
    }

    assert {:error, :empty_commits} = EventParser.parse("push", payload)
  end
end
