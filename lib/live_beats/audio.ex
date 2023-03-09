defmodule LiveBeats.Audio do
  def speech_to_text(path, chunk_time \\ 15.0, func) when chunk_time <= 30.0 do
    {:ok, stat} = LiveBeats.MP3Stat.parse(path)

    Stream.iterate(0, &(&1 + chunk_time))
    |> Enum.take_while(&(&1 < stat.duration))
    |> Task.async_stream(
      fn ss ->
        args = ~w(-i #{path} -ac 1 -ar 16k -f f32le -ss #{ss} -t #{chunk_time} -v quiet -)
        {data, 0} = System.cmd("ffmpeg", args)
        {ss, Nx.Serving.batched_run(WhisperServing, Nx.from_binary(data, :f32))}
      end,
      timeout: :infinity, max_concurrency: 4
    )
    |> Enum.map(fn {:ok, {ss, %{results: [%{text: text}]}}} -> func.(ss, text) end)
  end
end
