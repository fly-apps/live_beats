defmodule LiveBeats.MP3Stat do
  alias LiveBeats.MP3Stat

  defstruct duration: 0, path: nil

  def to_mmss(duration) when is_integer(duration) do
    hours = div(duration, 60 * 60)
    minutes = div(duration - (hours * 60 * 60), 60)
    seconds = rem(duration - (hours * 60 * 60) - (minutes * 60), 60)

    [minutes, seconds]
    |> Enum.map(fn count -> String.pad_leading("#{count}", 2, ["0"]) end)
    |> Enum.join(":")
  end

  def parse(path) do
    args = ["-v", "quiet", "-stats", "-i", path, "-f", "null", "-"]

    # "size=N/A time=00:03:00.00 bitrate=N/A speed= 674x"
    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {output, 0} -> parse_output(output, path)
      {_, 1} -> {:error, :bad_file}
      other -> {:error, other}
    end
  end

  defp parse_output(output, path) do
    with %{"time" => time} <- Regex.named_captures(~r/.*time=(?<time>[^\s]+).*/, output),
         [hours, minutes, seconds, _milliseconds] <- ints(String.split(time, [":", "."])) do
      duration = hours * 60 * 60 + minutes * 60 + seconds
      {:ok, %MP3Stat{duration: duration, path: path}}
    else
      _ -> {:error, :bad_duration}
    end
  end

  defp ints(strings) when is_list(strings) do
    Enum.flat_map(strings, fn str ->
      case Integer.parse(str) do
        {int, ""} -> [int]
        {_, _} -> []
        :error -> []
      end
    end)
  end
end
