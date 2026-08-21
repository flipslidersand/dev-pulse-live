defmodule DevPulseLiveWeb.WebhookControllerTest do
  use DevPulseLiveWeb.ConnCase, async: true

  defp secret, do: Application.get_env(:dev_pulse_live, :github_webhook_secret, "dev_secret")

  defp sign(body) do
    mac = :crypto.mac(:hmac, :sha256, secret(), body)
    "sha256=" <> Base.encode16(mac, case: :lower)
  end

  defp post_webhook(conn, payload, event_type) do
    body = Jason.encode!(payload)

    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("x-github-event", event_type)
    |> put_req_header("x-hub-signature-256", sign(body))
    |> post("/webhooks/github", body)
  end

  test "rejects missing signature with 401", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-github-event", "push")
      |> post("/webhooks/github", ~s({}))

    assert conn.status == 401
  end

  test "rejects invalid signature with 401", %{conn: conn} do
    wrong_sig = "sha256=" <> String.duplicate("0", 64)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-github-event", "push")
      |> put_req_header("x-hub-signature-256", wrong_sig)
      |> post("/webhooks/github", ~s({}))

    assert conn.status == 401
  end

  test "accepts push event and returns 200 ok", %{conn: conn} do
    payload = %{
      "commits" => [
        %{
          "id" => "abc123",
          "message" => "fix: bug",
          "url" => "https://github.com/owner/repo/commit/abc123"
        }
      ],
      "repository" => %{"full_name" => "owner/repo"},
      "pusher" => %{"name" => "testuser"}
    }

    conn = post_webhook(conn, payload, "push")
    assert conn.status == 200
    assert conn.resp_body == "ok"
  end

  test "accepts pull_request event and returns 200 ok", %{conn: conn} do
    payload = %{
      "action" => "opened",
      "pull_request" => %{
        "title" => "feat: new feature",
        "html_url" => "https://github.com/owner/repo/pull/1",
        "user" => %{"login" => "testuser"}
      },
      "repository" => %{"full_name" => "owner/repo"}
    }

    conn = post_webhook(conn, payload, "pull_request")
    assert conn.status == 200
    assert conn.resp_body == "ok"
  end

  test "accepts issues event and returns 200 ok", %{conn: conn} do
    payload = %{
      "action" => "opened",
      "issue" => %{
        "title" => "bug report",
        "html_url" => "https://github.com/owner/repo/issues/1",
        "user" => %{"login" => "testuser"}
      },
      "repository" => %{"full_name" => "owner/repo"}
    }

    conn = post_webhook(conn, payload, "issues")
    assert conn.status == 200
    assert conn.resp_body == "ok"
  end

  test "returns 200 ignored for unsupported event type", %{conn: conn} do
    conn = post_webhook(conn, %{"action" => "created"}, "star")
    assert conn.status == 200
    assert conn.resp_body == "ignored"
  end

  test "returns 422 for push event with empty commits", %{conn: conn} do
    payload = %{
      "commits" => [],
      "repository" => %{"full_name" => "owner/repo"},
      "pusher" => %{"name" => "testuser"}
    }

    conn = post_webhook(conn, payload, "push")
    assert conn.status == 422
  end
end
