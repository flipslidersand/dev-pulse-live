defmodule DevPulseLiveWeb.ActivityComponents do
  use DevPulseLiveWeb, :html

  attr :event, :map, required: true

  def event_card(assigns) do
    ~H"""
    <div class="card card-border bg-base-100 hover:bg-base-200 transition-colors">
      <div class="card-body p-4 flex-row items-start gap-3">
        <div class={"badge badge-lg mt-0.5 #{event_badge_class(@event.event_type)}"}>
          <.icon name={event_icon(@event.event_type)} class="size-3.5" />
        </div>
        <div class="flex-1 min-w-0">
          <p class="font-medium text-sm truncate">{@event.title || "(no title)"}</p>
          <div class="flex flex-wrap gap-x-3 gap-y-0.5 mt-1 text-xs text-base-content/60">
            <span class="font-mono">{@event.repo_name}</span>
            <span>@{@event.actor}</span>
            <span :if={@event.action}>{@event.action}</span>
          </div>
        </div>
        <a
          :if={@event.url}
          href={@event.url}
          target="_blank"
          rel="noopener"
          class="btn btn-ghost btn-xs shrink-0"
        >
          <.icon name="hero-arrow-top-right-on-square-micro" class="size-3.5" />
        </a>
      </div>
    </div>
    """
  end

  attr :commits, :integer, required: true
  attr :prs, :integer, required: true
  attr :issues, :integer, required: true

  def stats_bar(assigns) do
    ~H"""
    <div class="stats stats-horizontal shadow w-full">
      <div class="stat">
        <div class="stat-figure text-success">
          <.icon name="hero-arrow-up-circle" class="size-6" />
        </div>
        <div class="stat-title text-xs">Commits today</div>
        <div class="stat-value text-success text-2xl">{@commits}</div>
      </div>
      <div class="stat">
        <div class="stat-figure text-info">
          <.icon name="hero-code-bracket" class="size-6" />
        </div>
        <div class="stat-title text-xs">Pull Requests</div>
        <div class="stat-value text-info text-2xl">{@prs}</div>
      </div>
      <div class="stat">
        <div class="stat-figure text-warning">
          <.icon name="hero-exclamation-circle" class="size-6" />
        </div>
        <div class="stat-title text-xs">Issues</div>
        <div class="stat-value text-warning text-2xl">{@issues}</div>
      </div>
    </div>
    """
  end

  defp event_badge_class("push"), do: "badge-success"
  defp event_badge_class("pull_request"), do: "badge-info"
  defp event_badge_class("issues"), do: "badge-warning"
  defp event_badge_class(_), do: "badge-ghost"

  defp event_icon("push"), do: "hero-arrow-up-circle-micro"
  defp event_icon("pull_request"), do: "hero-code-bracket-micro"
  defp event_icon("issues"), do: "hero-exclamation-circle-micro"
  defp event_icon(_), do: "hero-bolt-micro"
end
