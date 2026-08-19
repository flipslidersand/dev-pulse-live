defmodule DevPulseLiveWeb.WebhookController do
  use DevPulseLiveWeb, :controller

  plug DevPulseLiveWeb.Plugs.VerifyGithubSignature

  alias DevPulseLive.Events
  alias DevPulseLive.Github.EventParser
  alias DevPulseLive.ActivityFeed.Broadcaster

  def github(conn, params) do
    event_type = conn |> get_req_header("x-github-event") |> List.first()

    with {:ok, attrs} <- EventParser.parse(event_type, params),
         {:ok, event} <- Events.create_event(attrs) do
      Broadcaster.broadcast_new_event(event)
      send_resp(conn, 200, "ok")
    else
      {:error, {:unsupported_event, _}} ->
        send_resp(conn, 200, "ignored")

      {:error, _reason} ->
        send_resp(conn, 422, "unprocessable")
    end
  end
end
