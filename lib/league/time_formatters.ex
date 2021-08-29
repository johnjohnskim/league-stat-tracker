defmodule League.TimeFormatters do
  use Timex

  @doc """
  Formats unix timestamps (in milliseconds) into a user-friendly string.
  """
  def format_datetime(start_time) do
    {:ok, datetime} =
      start_time
      |> div(1000)
      |> DateTime.from_unix!()
      # TODO: Stop hardcoding EST timezone
      |> Timezone.convert(Timezone.get("America/New_York"))
      |> Timex.format("%b %d, %I:%M %p", :strftime)

    datetime
  end

  @doc """
  Formats a duration (in seconds) into a user-friendly string.
  """
  def format_duration(duration) do
    duration_min = div(duration, 60)

    duration_sec =
      duration
      |> rem(60)
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    "#{duration_min}:#{duration_sec}"
  end
end
