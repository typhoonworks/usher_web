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
          |> append_path(route)
          |> URI.to_string()

        unverified_path(socket, socket.router, path, params)

      :nowhere ->
        "/"

      nil ->
        raise RuntimeError, "nothing stored in the :rounting key"
    end
  end

  @doc """
  Note, this function was copied from Elixir v1.18.4: https://github.com/elixir-lang/elixir/blob/v1.18.4/lib/elixir/lib/uri.ex#L999.
  `URI.append_path/2` is only introduced in Elixir v1.15, and since we support v1.14+,
  we need this function.

  Appends `path` to the given `uri`.

  Path must start with `/` and cannot contain additional URL components like
  fragments or query strings. This function further assumes the path is valid and
  it does not contain a query string or fragment parts.

  ## Examples

      iex> URI.append_path(URI.parse("http://example.com/foo/?x=1"), "/my-path") |> URI.to_string()
      "http://example.com/foo/my-path?x=1"

      iex> URI.append_path(URI.parse("http://example.com"), "my-path")
      ** (ArgumentError) path must start with "/", got: "my-path"

  """
  def append_path(%URI{}, "//" <> _ = path) do
    raise ArgumentError, ~s|path cannot start with "//", got: #{inspect(path)}|
  end

  def append_path(%URI{path: path} = uri, "/" <> rest = all) do
    cond do
      path == nil -> %{uri | path: all}
      path != "" and :binary.last(path) == ?/ -> %{uri | path: path <> rest}
      true -> %{uri | path: path <> all}
    end
  end

  def append_path(%URI{}, path) when is_binary(path) do
    raise ArgumentError, ~s|path must start with "/", got: #{inspect(path)}|
  end
end
