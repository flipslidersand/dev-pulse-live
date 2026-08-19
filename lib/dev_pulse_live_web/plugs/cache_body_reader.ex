defmodule DevPulseLiveWeb.Plugs.CacheBodyReader do
  @moduledoc false

  # Caches raw request body in conn.assigns[:raw_body] before Plug.Parsers
  # consumes the IO stream, so Webhook signature verification can still read it.
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &((&1 || "") <> body))
    {:ok, body, conn}
  end
end
