defmodule DevPulseLive.Repo.Migrations.CreateGithubEvents do
  use Ecto.Migration

  def change do
    create table(:github_events) do
      add :event_type, :string, null: false
      add :action, :string
      add :repo_name, :string, null: false
      add :title, :string
      add :url, :string
      add :sha, :string
      add :actor, :string, null: false
      add :payload, :map
      add :occurred_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:github_events, [:event_type, :occurred_at])
    create index(:github_events, [:actor, :occurred_at])
  end
end
