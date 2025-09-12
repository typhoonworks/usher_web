defmodule Usher.Web.Helpers.DateTimeHelpers do
  @moduledoc """
  Contains helper functions for date and time manipulation and formatting.
  """

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @month @day * 30
  @year @day * 365

  @end_of_day_time ~T[23:59:59.999999]

  def time_left_until(datetime) do
    now = DateTime.utc_now()

    case DateTime.diff(datetime, now, :second) do
      diff when diff > 0 -> format_duration(diff)
      _ -> "Expired"
    end
  end

  defp format_duration(s) when s == 0, do: "now"

  defp format_duration(s) when s > 0 and s < 45 do
    if s == 1, do: "In 1 second", else: "In #{s} seconds"
  end

  defp format_duration(s) when s >= 45 and s < 90, do: "In a minute"

  defp format_duration(s) when s >= 90 and s < 45 * @minute do
    minutes = div(s, @minute)
    "In #{minutes} minutes"
  end

  defp format_duration(s) when s >= 45 * @minute and s < 90 * @minute, do: "In an hour"

  defp format_duration(s) when s >= 90 * @minute and s < 22 * @hour do
    hours = div(s, @hour)
    "In #{hours} hours"
  end

  defp format_duration(s) when s >= 22 * @hour and s < 36 * @hour, do: "In a day"

  defp format_duration(s) when s >= 36 * @hour and s < 25 * @day do
    days = div(s, @day)
    "In #{days} days"
  end

  defp format_duration(s) when s >= 25 * @day and s < 45 * @day, do: "In a month"

  defp format_duration(s) when s >= 45 * @day and s < 345 * @day do
    months = div(s, @month)
    "In #{months} months"
  end

  defp format_duration(s) when s >= 345 * @day and s < 545 * @day, do: "In a year"

  defp format_duration(s) when s >= 546 * @day do
    years = div(s, @year)
    "In #{years} years"
  end

  defp format_duration(s) when s < 0, do: "Expired"

  def current_date(timezone \\ "Etc/UTC"), do: DateTime.now!(timezone) |> DateTime.to_date()

  @doc """
  Converts a date string to end of day UTC datetime in the specified timezone.

  ## Examples

      iex> date_to_end_of_day_utc("2025-02-16", "America/New_York")
      ~U[2025-02-17 04:59:59.999999Z]

      iex> date_to_end_of_day_utc("2025-02-16", "Europe/Lisbon")
      ~U[2025-02-16 23:59:59.999999Z]
  """
  def date_to_end_of_day_utc!(date_string, timezone)
      when is_binary(date_string) and date_string != "" do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        DateTime.new!(date, @end_of_day_time, timezone)

      _ ->
        nil
    end
  end

  def date_to_end_of_day_utc!(_, _), do: nil
end
