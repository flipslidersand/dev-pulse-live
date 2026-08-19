defmodule DevPulseLive.Github.WebhookVerifierTest do
  use ExUnit.Case, async: true

  alias DevPulseLive.Github.WebhookVerifier

  @secret "test_secret"
  @body ~s({"action":"opened"})

  defp sign(body, secret) do
    mac = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower)
    "sha256=#{mac}"
  end

  test "valid? returns true for correct signature" do
    sig = sign(@body, @secret)
    assert WebhookVerifier.valid?(@body, sig, @secret)
  end

  test "valid? returns false for wrong secret" do
    sig = sign(@body, "wrong_secret")
    refute WebhookVerifier.valid?(@body, sig, @secret)
  end

  test "valid? returns false for nil signature" do
    refute WebhookVerifier.valid?(@body, nil, @secret)
  end

  test "valid? returns false for malformed signature" do
    refute WebhookVerifier.valid?(@body, "not-a-valid-sig", @secret)
  end
end
