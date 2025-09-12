defmodule Usher.Web.LiveMount do
  @moduledoc false

  @doc """
  Sets up process dictionary and injects values into assigns.

  Gets merged with any `on_mount` hooks provided by the user.

  This on_mount hook will run before any user-defined on_mount hooks.
  """
  def on_mount(:default, _params, session, socket) do
    %{
      "prefix" => prefix,
      "live_path" => live_path,
      "live_transport" => live_transport,
      "csp_nonces" => csp_nonces,
      "resolver" => resolver,
      "user" => user,
      "access" => access
    } = session

    Process.put(:routing, {socket, prefix})

    socket =
      socket
      |> Phoenix.Component.assign(live_path: live_path, live_transport: live_transport)
      |> Phoenix.Component.assign(:page_title, "Usher Dashboard")
      |> Phoenix.Component.assign(:csp_nonces, csp_nonces)
      |> Phoenix.Component.assign(:resolver, resolver)
      |> Phoenix.Component.assign(user: user, access: access)

    {:cont, socket}
  end
end
