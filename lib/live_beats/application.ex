defmodule LiveBeats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def speech_to_text(serving, path, chunk_time_sec \\ 5) do
    {:ok, stat} = LiveBeats.MP3Stat.parse(path)
    chunks = trunc(Float.ceil(stat.duration / chunk_time_sec))

    {ffmpeg_args, _} =
      Enum.reduce(1..(chunks - 1), {[], 0}, fn _chunk, {args, ss} ->
        chunk_args = ~w(
            -i #{path}
            -ac 1
            -ar 16000
            -f f32le
            -ss #{ss}
            -t #{chunk_time_sec}
            -hide_banner
            -loglevel quiet
            pipe:1
            )

        {[chunk_args | args], ss + chunk_time_sec}
      end)

    ffmpeg_args
    |> Enum.reverse()
    |> Task.async_stream(
      fn args ->
        {data, 0} = System.cmd("ffmpeg", args)
        Nx.Serving.batched_run(serving, Nx.from_binary(data, :f32))
      end,
      timeout: 20_000
    )
    |> Enum.each(fn {:ok, %{results: [%{text: text} | _]}} ->
      IO.puts(">> #{text}")
    end)
  end

  @impl true
  def start(_type, _args) do
    LiveBeats.MediaLibrary.attach()
    topologies = Application.get_env(:libcluster, :topologies) || []

    {:ok, whisper} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})

    children = [
      {Nx.Serving,
       serving:
         Bumblebee.Audio.speech_to_text(whisper, featurizer, tokenizer,
           max_new_tokens: 100,
           defn_options: [batch_size: 10, compiler: EXLA]
         ),
       name: WhisperServing,
       batch_timeout: 100},
      {Cluster.Supervisor, [topologies, [name: LiveBeats.ClusterSupervisor]]},
      {Task.Supervisor, name: LiveBeats.TaskSupervisor},
      # Start the Ecto repository
      LiveBeats.Repo,
      LiveBeats.ReplicaRepo,
      # Start the Telemetry supervisor
      LiveBeatsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveBeats.PubSub},
      # start presence
      LiveBeatsWeb.Presence,
      {Finch, name: LiveBeats.Finch},
      # Start the Endpoint (http/https)
      LiveBeatsWeb.Endpoint,
      # Expire songs every six hours
      {LiveBeats.SongsCleaner, interval: {3600 * 6, :second}}

      # Start a worker by calling: LiveBeats.Worker.start_link(arg)
      # {LiveBeats.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveBeats.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveBeatsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
