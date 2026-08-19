defmodule DevPulseLiveWeb.Plugs.VerifyGithubSignature do
  import Plug.Conn
  alias DevPulseLive.Github.WebhookVerifier

  def init(opts), do: opts

  def call(conn, _opts) do
    secret = Application.fetch_env!(:dev_pulse_live, :github_webhook_secret)
    sig = conn |> get_req_header("x-hub-signature-256") |> List.first()
    body = conn.assigns[:raw_body] || ""

    if WebhookVerifier.valid?(body, sig, secret) do
      conn
    else
      conn
      |> send_resp(401, "invalid signature")
      |> halt()
    end
  end
end
