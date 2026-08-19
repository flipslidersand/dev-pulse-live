defmodule DevPulseLiveWeb.DashboardLiveTest do
  use DevPulseLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias DevPulseLive.Events

  defp create_event(overrides) do
    overrides = Map.new(overrides)

    attrs =
      Map.merge(
        %{
          event_type: "push",
          repo_name: "owner/repo",
          actor: "testuser",
          title: "fix: something",
          occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
        },
        overrides
      )

    {:ok, event} = Events.create_event(attrs)
    event
  end

  test "renders dashboard with stats", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "dev-pulse"
    assert html =~ "Commits today"
    assert html =~ "Pull Requests"
    assert html =~ "Issues"
  end

  test "displays existing events on mount", %{conn: conn} do
    create_event(%{title: "feat: initial commit"})
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "feat: initial commit"
  end

  test "filter tabs switch event type", %{conn: conn} do
    create_event(%{event_type: "push", title: "commit msg"})
    create_event(%{event_type: "pull_request", title: "PR title"})

    {:ok, view, _html} = live(conn, "/")

    html = view |> element("button", "Commits") |> render_click()
    assert html =~ "commit msg"
    refute html =~ "PR title"

    html = view |> element("button", "PRs") |> render_click()
    assert html =~ "PR title"
    refute html =~ "commit msg"
  end

  test "receives realtime event via PubSub", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    {:ok, event} =
      Events.create_event(%{
        event_type: "push",
        repo_name: "owner/repo",
        actor: "testuser",
        title: "realtime update",
        occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    send(view.pid, {:new_event, event})

    assert render(view) =~ "realtime update"
  end

  test "realtime event respects active filter", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view |> element("button", "PRs") |> render_click()

    {:ok, push_event} =
      Events.create_event(%{
        event_type: "push",
        repo_name: "owner/repo",
        actor: "testuser",
        title: "should not appear",
        occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    send(view.pid, {:new_event, push_event})
    refute render(view) =~ "should not appear"
  end
end
