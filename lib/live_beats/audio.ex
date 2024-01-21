defmodule LiveBeats.Audio do
  def speech_to_text(path, chunk_time, func) do
    {:ok, stat} = LiveBeats.MP3Stat.parse(path)

    0..stat.duration//chunk_time
    |> Task.async_stream(
      fn ss ->
        args = ~w(-ac 1 -ar 16k -f f32le -ss #{ss} -t #{chunk_time} -v quiet -)
        {data, 0} = System.cmd("ffmpeg", ["-i", path] ++ args)
        {ss, Nx.Serving.batched_run(WhisperServing, Nx.from_binary(data, :f32))}
      end,
      max_concurrency: 2,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, {ss, %{results: [%{text: text}]}}} -> func.(ss, text) end)
  end
end
