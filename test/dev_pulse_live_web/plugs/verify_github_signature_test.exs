defmodule DevPulseLiveWeb.Plugs.VerifyGithubSignatureTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  alias DevPulseLiveWeb.Plugs.VerifyGithubSignature

  defp secret, do: Application.get_env(:dev_pulse_live, :github_webhook_secret, "dev_secret")

  defp sign(body) do
    mac = :crypto.mac(:hmac, :sha256, secret(), body)
    "sha256=" <> Base.encode16(mac, case: :lower)
  end

  defp build_conn(body, sig) do
    conn = conn(:post, "/webhooks/github", body)
    conn = put_in(conn.assigns[:raw_body], body)

    if sig do
      put_req_header(conn, "x-hub-signature-256", sig)
    else
      conn
    end
  end

  test "passes conn through when signature is valid" do
    body = ~s({"hello":"world"})
    conn = build_conn(body, sign(body))
    result = VerifyGithubSignature.call(conn, [])
    refute result.halted
  end

  test "halts with 401 when signature is invalid" do
    wrong_sig = "sha256=" <> String.duplicate("0", 64)
    conn = build_conn(~s({"hello":"world"}), wrong_sig)
    result = VerifyGithubSignature.call(conn, [])
    assert result.halted
    assert result.status == 401
  end

  test "halts with 401 when signature header is missing" do
    conn = build_conn(~s({}), nil)
    result = VerifyGithubSignature.call(conn, [])
    assert result.halted
    assert result.status == 401
  end

  test "halts with 401 when signature has wrong prefix" do
    conn = build_conn(~s({}), "sha1=abc")
    result = VerifyGithubSignature.call(conn, [])
    assert result.halted
    assert result.status == 401
  end

  test "init returns opts unchanged" do
    assert VerifyGithubSignature.init(foo: :bar) == [foo: :bar]
  end
end
