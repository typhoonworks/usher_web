defmodule Usher.Web.Helpers.MapsHelpers do
  @moduledoc false

  @doc """
  Converts map keys from strings to atoms, ensuring existing atoms are used.
  Special form fields starting with "_" are preserved as string keys.
  """
  def atomize_keys(%{__struct__: _} = struct), do: struct

  def atomize_keys(%{} = map) do
    has_underscore_keys =
      Enum.any?(map, fn {k, _} ->
        is_binary(k) && String.starts_with?(k, "_")
      end)

    if has_underscore_keys && association_params?(map) do
      map
      |> Enum.map(fn {k, v} ->
        key = if is_atom(k), do: Atom.to_string(k), else: k
        {key, atomize_value(v)}
      end)
      |> Enum.into(%{})
    else
      map
      |> Enum.map(fn {k, v} ->
        # credo:disable-for-next-line Credo.Check.Refactor.Nesting
        key = if is_binary(k), do: safe_to_atom(k), else: k
        {key, atomize_value(v)}
      end)
      |> Enum.into(%{})
    end
  end

  def atomize_keys(non_map), do: non_map

  defp atomize_value(value) when is_map(value), do: atomize_keys(value)

  defp atomize_value(value) when is_list(value) do
    Enum.map(value, fn
      item when is_map(item) -> atomize_keys(item)
      other -> other
    end)
  end

  defp atomize_value(value), do: value

  defp safe_to_atom(string) do
    try do
      String.to_existing_atom(string)
    rescue
      ArgumentError -> string
    end
  end

  defp association_params?(map) do
    Enum.any?(map, fn {k, _} ->
      k == "_persistent_id" || k == :_persistent_id
    end)
  end
end
