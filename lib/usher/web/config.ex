defmodule Usher.Web.Config do
  @moduledoc """
  Provides functions to retrieve configuration values for the Usher Web application.
  """

  @doc """
  Returns the URL where users will be redirected when they click invitation links.

  Defaults to "http://localhost:4000" if not configured.
  """
  @spec invitation_redirect_url() :: String.t()
  def invitation_redirect_url do
    Application.get_env(:usher_web, :invitation_redirect_url, "http://localhost:4000")
  end
end
