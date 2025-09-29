defmodule Usher.Web.ConfigTest do
  use ExUnit.Case, async: true

  import Mimic

  alias Usher.Web.Config

  setup :verify_on_exit!

  describe "invitation_redirect_url/0" do
    test "returns configured invitation redirect URL" do
      Application
      |> expect(:get_env, fn :usher_web, :invitation_redirect_url, _default ->
        "https://example.com"
      end)

      assert Config.invitation_redirect_url() == "https://example.com"
    end

    test "returns default when not configured" do
      Application
      |> expect(:get_env, fn :usher_web, :invitation_redirect_url, default ->
        default
      end)

      assert Config.invitation_redirect_url() == "http://localhost:4000"
    end
  end
end
