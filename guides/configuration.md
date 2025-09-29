# Configuration

This guide covers configuration options for Usher Web and the underlying Usher library.

## Usher Web Configuration

Usher Web provides its own configuration options that should be added to your `config/config.exs` file:

```elixir
config :usher_web,
  invitation_redirect_url: "https://myapp.com"
```

### Configuration Options

#### `:invitation_redirect_url`

The URL where users will be redirected when they click invitation links.

- **Type**: `String.t()`
- **Default**: `"http://localhost:4000"`
- **Required**: No

**Example:**

```elixir
config :usher_web,
  invitation_redirect_url: "https://myapp.com"
```

When configured, invitation links will redirect users to this URL. For example, if you set it to `"https://myapp.com"`, the generated invitation links will look like `https://myapp.com/invitations/abcdef`.

## Usher Library Configuration

Usher Web depends on the [Usher library](https://hexdocs.pm/usher) for core invitation management functionality. You need to configure Usher separately in your `config/config.exs` file.

For more detailed information about Usher library configuration options, see the [Usher Configuration guide](https://hexdocs.pm/usher/configuration.html).