defmodule DevPulseLive.Github.Client do
  @base_url "https://api.github.com"

  def fetch_events(actor, etag \\ nil) do
    token = Application.get_env(:dev_pulse_live, :github_token, "")
    headers = build_headers(token, etag)
    opts = [headers: headers] ++ req_opts()

    case Req.get("#{@base_url}/users/#{actor}/events", opts) do
      {:ok, %{status: 304}} ->
        {:ok, :not_modified}

      {:ok, %{status: 200, body: items, headers: resp_headers}} ->
        new_etag = get_header(resp_headers, "etag")

        events =
          items
          |> Enum.map(&to_event_attrs/1)
          |> Enum.reject(&is_nil/1)

        {:ok, events, new_etag}

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp req_opts do
    case Application.get_env(:dev_pulse_live, :req_plug) do
      nil -> []
      plug -> [plug: plug, retry: false]
    end
  end

  defp build_headers(token, etag) do
    base = [
      {"Authorization", "Bearer #{token}"},
      {"Accept", "application/vnd.github+json"},
      {"X-GitHub-Api-Version", "2022-11-28"}
    ]

    if etag, do: [{"If-None-Match", etag} | base], else: base
  end

  defp get_header(headers, name) do
    case Map.get(headers, name) do
      [value | _] -> value
      _ -> nil
    end
  end

  defp to_event_attrs(%{
         "type" => "PushEvent",
         "repo" => repo,
         "actor" => actor,
         "payload" => payload
       }) do
    commits = payload["commits"] || []

    case commits do
      [commit | _] ->
        %{
          event_type: "push",
          repo_name: repo["name"],
          title: first_line(commit["message"]),
          url: "https://github.com/#{repo["name"]}/commit/#{commit["sha"]}",
          sha: commit["sha"],
          actor: actor["login"],
          payload: %{},
          occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }

      _ ->
        nil
    end
  end

  defp to_event_attrs(%{
         "type" => "PullRequestEvent",
         "repo" => repo,
         "actor" => actor,
         "payload" => payload
       }) do
    pr = payload["pull_request"] || %{}

    %{
      event_type: "pull_request",
      action: payload["action"],
      repo_name: repo["name"],
      title: pr["title"],
      url: pr["html_url"],
      actor: actor["login"],
      payload: %{},
      occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  defp to_event_attrs(%{
         "type" => "IssuesEvent",
         "repo" => repo,
         "actor" => actor,
         "payload" => payload
       }) do
    issue = payload["issue"] || %{}

    %{
      event_type: "issues",
      action: payload["action"],
      repo_name: repo["name"],
      title: issue["title"],
      url: issue["html_url"],
      actor: actor["login"],
      payload: %{},
      occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  defp to_event_attrs(_), do: nil

  defp first_line(nil), do: nil

  defp first_line(message) do
    message |> String.split("\n") |> List.first() |> String.slice(0, 200)
  end
end
