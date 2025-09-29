# Getting Started

This guide will walk you through setting up Usher Web and creating your first invitation.

## Prerequisites

Before you begin, make sure you have:

- Completed the [Installation](installation.md) steps
- A running Phoenix application with support for LiveView (you don't need to be using LiveView elsewhere in your app, but it must be set up to support LiveView routes)
- PostgreSQL database set up and migrated

## Configuration

### Usher Library Configuration

You need to configure the underlying [Usher library](https://hexdocs.pm/usher) that Usher Web depends on.

Configure Usher in your `config/config.exs` file.

Here's a basic example, to get you started:

```elixir
# Only the required configuration options are shown below.
config :usher,
  repo: MyApp.Repo,
  validations: %{
    invitation_usage: %{
      valid_usage_entity_types: [:user, :company],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  }
```

You can find details about configuration options in [Usher's Configuration guide](https://hexdocs.pm/usher/configuration.html).

### Usher Web Configuration

Usher Web needs its own configuration:

```elixir
config :usher_web,
  invitation_redirect_url: "https://myapp.com"
```

Currently, you can only configure the `:invitation_redirect_url`, which specifies where users will be redirected when they click invitation links. Defaults to `"http://localhost:4000"` if not provided. For example, if you set it to `"https://myapp.com"`, the generated invitation links will look like `https://myapp.com/invitations/abcdef`.

See the [Configuration guide](configuration.md) for more details.

## Routing to Usher Web Views

To use Usher Web, you need to add its routes to your Phoenix Router:

```elixir
# In your lib/my_app_web/router.ex file
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  import Usher.Web.Router

  scope "/" do
    pipe_through [:browser, :require_authenticated_user] # Don't forget about auth!

    usher_dashboard("/usher")
  end
end
```

Now you can go to the `/usher` path in your application to access the Usher Web interface.

## Authentication and Authorization

For handling auth for Usher Web, you need to implement a custom resolver module by creating a module that uses the `Usher.Web.Resolver` behaviour and implements its callbacks. See module docs for `Usher.Web.Authentication` and `Usher.Web.Resolver` for details.
