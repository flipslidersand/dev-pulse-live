defmodule DevPulseLive.Events.GithubEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "github_events" do
    field :event_type, :string
    field :action, :string
    field :repo_name, :string
    field :title, :string
    field :url, :string
    field :sha, :string
    field :actor, :string
    field :payload, :map
    field :occurred_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @required [:event_type, :repo_name, :actor, :occurred_at]
  @optional [:action, :title, :url, :sha, :payload]

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:event_type, ["push", "pull_request", "issues"])
  end
end
