defmodule DevPulseLive.ActivityFeed.Broadcaster do
  @topic "activity_feed"

  def broadcast_new_event(event) do
    Phoenix.PubSub.broadcast(DevPulseLive.PubSub, @topic, {:new_event, event})
  end

  def subscribe do
    Phoenix.PubSub.subscribe(DevPulseLive.PubSub, @topic)
  end
end
