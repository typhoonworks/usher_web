defmodule Usher.Web.Helpers.DateTimeHelpersTest do
  use Usher.Web.DataCase, async: true
  use Mimic

  alias Usher.Web.Helpers.DateTimeHelpers

  describe "time_left_until/1" do
    test "returns 'Expired' for datetime in the past" do
      past_datetime = DateTime.utc_now() |> DateTime.add(-1, :hour)
      assert DateTimeHelpers.time_left_until(past_datetime) == "Expired"
    end

    test "returns 'now' for exact current time" do
      fixed_time = ~U[2025-01-01 12:00:00Z]

      DateTime
      |> stub(:utc_now, fn -> fixed_time end)

      result = DateTimeHelpers.time_left_until(fixed_time)
      assert result == "Expired"
    end

    test "returns seconds for short durations (1-44 seconds)" do
      fixed_time = ~U[2025-01-01 12:00:00Z]

      DateTime
      |> stub(:utc_now, fn -> fixed_time end)

      future_1s = DateTime.add(fixed_time, 1, :second)
      future_30s = DateTime.add(fixed_time, 30, :second)

      assert DateTimeHelpers.time_left_until(future_1s) == "In 1 second"
      assert DateTimeHelpers.time_left_until(future_30s) == "In 30 seconds"
    end

    test "returns 'In a minute' for 45-89 seconds" do
      now = DateTime.utc_now()
      future_45s = DateTime.add(now, 45, :second)
      future_89s = DateTime.add(now, 89, :second)

      assert DateTimeHelpers.time_left_until(future_45s) == "In a minute"
      assert DateTimeHelpers.time_left_until(future_89s) == "In a minute"
    end

    test "returns minutes for 90 seconds to 44 minutes" do
      now = DateTime.utc_now()
      future_2min = DateTime.add(now, 120, :second)
      future_30min = DateTime.add(now, 30 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_2min) == "In 2 minutes"
      assert DateTimeHelpers.time_left_until(future_30min) == "In 30 minutes"
    end

    test "returns 'In an hour' for 45-89 minutes" do
      now = DateTime.utc_now()
      future_45min = DateTime.add(now, 45 * 60, :second)
      future_89min = DateTime.add(now, 89 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_45min) == "In an hour"
      assert DateTimeHelpers.time_left_until(future_89min) == "In an hour"
    end

    test "returns hours for 90 minutes to 21 hours" do
      now = DateTime.utc_now()
      future_2h = DateTime.add(now, 2 * 60 * 60, :second)
      future_12h = DateTime.add(now, 12 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_2h) == "In 2 hours"
      assert DateTimeHelpers.time_left_until(future_12h) == "In 12 hours"
    end

    test "returns 'In a day' for 22-35 hours" do
      now = DateTime.utc_now()
      future_22h = DateTime.add(now, 22 * 60 * 60, :second)
      future_35h = DateTime.add(now, 35 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_22h) == "In a day"
      assert DateTimeHelpers.time_left_until(future_35h) == "In a day"
    end

    test "returns days for 36 hours to 24 days" do
      now = DateTime.utc_now()
      future_2d = DateTime.add(now, 2 * 24 * 60 * 60, :second)
      future_15d = DateTime.add(now, 15 * 24 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_2d) == "In 2 days"
      assert DateTimeHelpers.time_left_until(future_15d) == "In 15 days"
    end

    test "returns 'In a month' for 25-44 days" do
      now = DateTime.utc_now()
      future_25d = DateTime.add(now, 25 * 24 * 60 * 60, :second)
      future_44d = DateTime.add(now, 44 * 24 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_25d) == "In a month"
      assert DateTimeHelpers.time_left_until(future_44d) == "In a month"
    end

    test "returns months for 45-344 days" do
      now = DateTime.utc_now()
      future_60d = DateTime.add(now, 60 * 24 * 60 * 60, :second)
      future_300d = DateTime.add(now, 300 * 24 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_60d) == "In 2 months"
      assert DateTimeHelpers.time_left_until(future_300d) == "In 10 months"
    end

    test "returns 'In a year' for 345-544 days" do
      now = DateTime.utc_now()
      future_345d = DateTime.add(now, 345 * 24 * 60 * 60, :second)
      future_544d = DateTime.add(now, 544 * 24 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_345d) == "In a year"
      assert DateTimeHelpers.time_left_until(future_544d) == "In a year"
    end

    test "returns years for 546+ days" do
      now = DateTime.utc_now()
      future_2y = DateTime.add(now, 2 * 365 * 24 * 60 * 60, :second)
      future_5y = DateTime.add(now, 5 * 365 * 24 * 60 * 60, :second)

      assert DateTimeHelpers.time_left_until(future_2y) == "In 2 years"
      assert DateTimeHelpers.time_left_until(future_5y) == "In 5 years"
    end
  end

  describe "current_date/1" do
    test "returns current date in UTC by default" do
      assert %Date{} = date = DateTimeHelpers.current_date()
      assert Date.compare(date, Date.utc_today()) in [:eq, :lt, :gt]
    end

    test "returns current date in specified timezone" do
      date_utc = DateTimeHelpers.current_date("Etc/UTC")
      date_ny = DateTimeHelpers.current_date("America/New_York")

      assert %Date{} = date_utc
      assert %Date{} = date_ny
    end
  end

  describe "date_to_end_of_day_utc!/2" do
    test "converts date string to end of day UTC datetime" do
      result = DateTimeHelpers.date_to_end_of_day_utc!("2025-02-16", "Etc/UTC")

      assert %DateTime{} = result
      assert result.year == 2025
      assert result.month == 2
      assert result.day == 16
      assert result.hour == 23
      assert result.minute == 59
      assert result.second == 59
      assert result.microsecond == {999_999, 6}
    end

    test "converts Date struct to end of day UTC datetime" do
      date = ~D[2025-02-16]
      result = DateTimeHelpers.date_to_end_of_day_utc!(date, "Etc/UTC")

      assert %DateTime{} = result
      assert result.year == 2025
      assert result.month == 2
      assert result.day == 16
      assert result.hour == 23
      assert result.minute == 59
      assert result.second == 59
    end

    test "handles timezone conversion correctly" do
      result_utc = DateTimeHelpers.date_to_end_of_day_utc!("2025-02-16", "Etc/UTC")
      result_ny = DateTimeHelpers.date_to_end_of_day_utc!("2025-02-16", "America/New_York")

      assert DateTime.compare(result_ny, result_utc) == :gt
    end

    test "returns nil for invalid date string" do
      assert DateTimeHelpers.date_to_end_of_day_utc!("invalid-date", "Etc/UTC") == nil
      assert DateTimeHelpers.date_to_end_of_day_utc!("", "Etc/UTC") == nil
    end

    test "returns nil for non-string, non-Date input" do
      assert DateTimeHelpers.date_to_end_of_day_utc!(nil, "Etc/UTC") == nil
      assert DateTimeHelpers.date_to_end_of_day_utc!(123, "Etc/UTC") == nil
      assert DateTimeHelpers.date_to_end_of_day_utc!([], "Etc/UTC") == nil
    end
  end
end
