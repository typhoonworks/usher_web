defmodule Usher.Web.Helpers.PathHelpers do
  @moduledoc false

  import Phoenix.VerifiedRoutes

  def usher_path do
    usher_path("/")
  end

  @doc """
  Construct a path to a dashboard page with optional params.

  Routing is based on a socket and prefix tuple stored in the process dictionary. Routing
  can be disabled for testing by setting the value to `:nowhere`.
  """
  def usher_path(route, params \\ %{})

  def usher_path(route, params) when is_list(route) do
    route
    |> Enum.join("/")
    |> then(&"/#{&1}")
    |> usher_path(params)
  end

  def usher_path(route, params) do
    case Process.get(:routing) do
      {socket, prefix} ->
        path =
          prefix
          |> URI.new!()
          |> URI.append_path(route)
          |> URI.to_string()

        unverified_path(socket, socket.router, path, params)

      :nowhere ->
        "/"

      nil ->
        raise RuntimeError, "nothing stored in the :rounting key"
    end
  end
end
