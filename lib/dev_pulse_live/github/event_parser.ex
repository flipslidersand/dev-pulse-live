defmodule DevPulseLive.Github.EventParser do
  @moduledoc false

  @doc """
  Parses a GitHub Webhook payload into internal event attrs.
  Returns {:ok, attrs} or {:error, reason}.
  """
  def parse("push", %{"commits" => [commit | _], "repository" => repo, "pusher" => pusher}) do
    {:ok,
     %{
       event_type: "push",
       repo_name: repo["full_name"],
       title: first_line(commit["message"]),
       url: commit["url"],
       sha: commit["id"],
       actor: pusher["name"],
       payload: %{},
       occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
     }}
  end

  def parse("push", _payload), do: {:error, :empty_commits}

  def parse("pull_request", %{"pull_request" => pr, "action" => action, "repository" => repo}) do
    {:ok,
     %{
       event_type: "pull_request",
       action: action,
       repo_name: repo["full_name"],
       title: pr["title"],
       url: pr["html_url"],
       actor: pr["user"]["login"],
       payload: %{},
       occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
     }}
  end

  def parse("issues", %{"issue" => issue, "action" => action, "repository" => repo}) do
    {:ok,
     %{
       event_type: "issues",
       action: action,
       repo_name: repo["full_name"],
       title: issue["title"],
       url: issue["html_url"],
       actor: issue["user"]["login"],
       payload: %{},
       occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
     }}
  end

  def parse(type, _payload), do: {:error, {:unsupported_event, type}}

  defp first_line(message) when is_binary(message) do
    message |> String.split("\n") |> List.first() |> String.slice(0, 200)
  end

  defp first_line(_), do: nil
end
