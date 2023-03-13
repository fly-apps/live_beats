defmodule LiveBeats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    LiveBeats.MediaLibrary.attach()
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
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
