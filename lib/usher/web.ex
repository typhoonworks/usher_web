defmodule Usher.Web do
  @moduledoc false

  def static_paths, do: ~w(app.css app.js favicon.ico)

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Usher.Web.Layouts, :live}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import Usher.Web.CoreComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      import Usher.Web.Helpers.DateTimeHelpers
      import Usher.Web.Helpers.PathHelpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
