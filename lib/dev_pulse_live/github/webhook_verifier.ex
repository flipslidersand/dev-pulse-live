defmodule DevPulseLive.Github.WebhookVerifier do
  @moduledoc false

  @doc """
  Returns true if the HMAC-SHA256 signature in `sig` matches the
  expected signature computed from `body` and `secret`.

  Uses constant-time comparison to prevent timing attacks.
  """
  @spec valid?(binary(), binary() | nil, binary()) :: boolean()
  def valid?(_body, nil, _secret), do: false

  def valid?(body, "sha256=" <> hex_digest, secret) do
    expected =
      :crypto.mac(:hmac, :sha256, secret, body)
      |> Base.encode16(case: :lower)

    :crypto.hash_equals(expected, hex_digest)
  end

  def valid?(_body, _sig, _secret), do: false
end
