# Installation

## Requirements

Usher requires:

- Elixir 1.14 or later
- OTP 25 or later
- PostgreSQL

> **Note**: Usher Web may work with earlier versions of Elixir and OTP, but it wasn't tested against them.

## Adding Usher Web to Your Project

Add `usher_web` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:usher_web, "~> 1.0.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Database Setup

Usher Web requires database tables to store invitation data. You'll need to create and run a migration to set up these tables.

First, follow the database setup instructions for the [Usher library](https://hexdocs.pm/usher/installation.html#database-setup).

Once you've set up the Usher database tables, continue on to the [Getting Started guide](getting-started.md) for configuration and basic usage examples.
