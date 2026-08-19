defmodule DevPulseLive.Repo do
  use Ecto.Repo,
    otp_app: :dev_pulse_live,
    adapter: Ecto.Adapters.Postgres
end
