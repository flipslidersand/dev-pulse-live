defmodule DevPulseLive.EventsTest do
  use DevPulseLive.DataCase, async: true

  alias DevPulseLive.Events

  defp event_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        event_type: "push",
        repo_name: "owner/repo",
        actor: "testuser",
        occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
      },
      overrides
    )
  end

  test "create_event/1 creates a valid event" do
    assert {:ok, event} = Events.create_event(event_attrs())
    assert event.event_type == "push"
    assert event.actor == "testuser"
  end

  test "create_event/1 returns error for invalid event_type" do
    assert {:error, changeset} = Events.create_event(event_attrs(%{event_type: "star"}))
    assert changeset.errors[:event_type]
  end

  test "list_recent_events/1 returns events ordered by occurred_at desc" do
    t1 = ~U[2026-01-01 00:00:00Z]
    t2 = ~U[2026-01-02 00:00:00Z]
    {:ok, _} = Events.create_event(event_attrs(%{occurred_at: t1}))
    {:ok, _} = Events.create_event(event_attrs(%{occurred_at: t2}))

    [first | _] = Events.list_recent_events()
    assert first.occurred_at == t2
  end

  test "list_events_by_type/2 filters by event_type" do
    {:ok, _} = Events.create_event(event_attrs(%{event_type: "push"}))
    {:ok, _} = Events.create_event(event_attrs(%{event_type: "pull_request"}))

    events = Events.list_events_by_type("push")
    assert Enum.all?(events, &(&1.event_type == "push"))
  end

  test "stats_today/0 returns counts for today" do
    {:ok, _} = Events.create_event(event_attrs(%{event_type: "push"}))
    {:ok, _} = Events.create_event(event_attrs(%{event_type: "pull_request"}))
    {:ok, _} = Events.create_event(event_attrs(%{event_type: "issues"}))

    stats = Events.stats_today()
    assert stats.commits >= 1
    assert stats.prs >= 1
    assert stats.issues >= 1
  end
end
