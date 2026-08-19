defmodule DevPulseLive.ActivityFeed.Poller do
  use GenServer
  require Logger

  alias DevPulseLive.Events
  alias DevPulseLive.Github.Client
  alias DevPulseLive.ActivityFeed.Broadcaster

  @default_interval_ms 300_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    interval =
      Application.get_env(:dev_pulse_live, __MODULE__, [])[:interval_ms] || @default_interval_ms

    send(self(), :poll)
    {:ok, %{interval_ms: interval, etag: nil}}
  end

  @impl true
  def handle_info(:poll, state) do
    state = do_poll(state)
    Process.send_after(self(), :poll, state.interval_ms)
    {:noreply, state}
  end

  defp do_poll(state) do
    actor = Application.get_env(:dev_pulse_live, :github_actor, "")

    case Client.fetch_events(actor, state.etag) do
      {:ok, :not_modified} ->
        state

      {:ok, events, new_etag} ->
        Enum.each(events, fn attrs ->
          case Events.create_event(attrs) do
            {:ok, event} -> Broadcaster.broadcast_new_event(event)
            {:error, reason} -> Logger.warning("Poller: failed to save event: #{inspect(reason)}")
          end
        end)

        %{state | etag: new_etag}

      {:error, reason} ->
        Logger.warning("Poller: GitHub API error: #{inspect(reason)}")
        state
    end
  end
end
