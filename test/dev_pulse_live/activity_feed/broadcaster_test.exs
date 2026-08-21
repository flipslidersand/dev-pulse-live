defmodule DevPulseLive.ActivityFeed.BroadcasterTest do
  use ExUnit.Case, async: true

  alias DevPulseLive.ActivityFeed.Broadcaster

  test "subscribe/0 returns :ok" do
    assert :ok = Broadcaster.subscribe()
  end

  test "broadcast_new_event/1 delivers message to subscribers" do
    Broadcaster.subscribe()
    event = %{id: 1, event_type: "push", title: "realtime update"}
    Broadcaster.broadcast_new_event(event)
    assert_receive {:new_event, ^event}, 500
  end

  test "non-subscriber does not receive broadcast" do
    event = %{id: 2, event_type: "push", title: "silent update"}
    Broadcaster.broadcast_new_event(event)
    refute_receive {:new_event, ^event}, 100
  end
end
