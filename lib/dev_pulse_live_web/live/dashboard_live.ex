defmodule DevPulseLiveWeb.DashboardLive do
  use DevPulseLiveWeb, :live_view

  alias DevPulseLive.Events
  alias DevPulseLive.ActivityFeed.Broadcaster
  alias DevPulseLiveWeb.ActivityComponents

  @filters ["all", "push", "pull_request", "issues"]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Broadcaster.subscribe()

    stats = Events.stats_today()
    events = load_events("all")

    socket =
      socket
      |> assign(:page_title, "dev-pulse")
      |> assign(:filter, "all")
      |> assign(:stats, stats)
      |> assign(:event_count, length(events))
      |> stream(:events, events)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold">dev-pulse</h1>
          <span class="badge badge-ghost badge-sm">live</span>
        </div>

        <ActivityComponents.stats_bar
          commits={@stats.commits}
          prs={@stats.prs}
          issues={@stats.issues}
        />

        <div class="tabs tabs-box">
          <button
            :for={f <- ["all", "push", "pull_request", "issues"]}
            class={"tab #{if @filter == f, do: "tab-active"}"}
            phx-click="filter"
            phx-value-type={f}
          >
            {filter_label(f)}
          </button>
        </div>

        <div id="events" phx-update="stream" class="space-y-2">
          <div
            :for={{id, event} <- @streams.events}
            id={id}
            class="animate-[fadeIn_0.2s_ease-out]"
          >
            <ActivityComponents.event_card event={event} />
          </div>
        </div>

        <div :if={@event_count == 0} class="text-center py-16 text-base-content/50">
          <.icon name="hero-inbox" class="size-10 mx-auto mb-3" />
          <p>No activity yet. Push some code!</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("filter", %{"type" => type}, socket) when type in @filters do
    events = load_events(type)

    socket =
      socket
      |> assign(:filter, type)
      |> assign(:event_count, length(events))
      |> stream(:events, events, reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_event, event}, socket) do
    stats = Events.stats_today()

    socket =
      socket
      |> assign(:stats, stats)
      |> maybe_stream_insert(event)

    {:noreply, socket}
  end

  defp maybe_stream_insert(socket, event) do
    filter = socket.assigns.filter

    if filter == "all" or filter == event.event_type do
      socket
      |> update(:event_count, &(&1 + 1))
      |> stream_insert(:events, event, at: 0)
    else
      socket
    end
  end

  defp load_events("all"), do: Events.list_recent_events(limit: 50)
  defp load_events(type), do: Events.list_events_by_type(type, limit: 50)

  defp filter_label("all"), do: "All"
  defp filter_label("push"), do: "Commits"
  defp filter_label("pull_request"), do: "PRs"
  defp filter_label("issues"), do: "Issues"
end
