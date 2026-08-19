defmodule DevPulseLive.Events do
  import Ecto.Query
  alias DevPulseLive.Repo
  alias DevPulseLive.Events.GithubEvent

  def list_recent_events(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    GithubEvent
    |> order_by([e], desc: e.occurred_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_events_by_type(type, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    GithubEvent
    |> where([e], e.event_type == ^type)
    |> order_by([e], desc: e.occurred_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def create_event(attrs) do
    %GithubEvent{}
    |> GithubEvent.changeset(attrs)
    |> Repo.insert()
  end

  def stats_today do
    today = DateTime.utc_now() |> DateTime.to_date()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")

    counts =
      GithubEvent
      |> where([e], e.occurred_at >= ^start_of_day)
      |> group_by([e], e.event_type)
      |> select([e], {e.event_type, count(e.id)})
      |> Repo.all()
      |> Map.new()

    %{
      commits: Map.get(counts, "push", 0),
      prs: Map.get(counts, "pull_request", 0),
      issues: Map.get(counts, "issues", 0)
    }
  end
end
