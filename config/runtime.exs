import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :live_beats, LiveBeatsWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :flame, :terminator, log: :info
  config :flame, :backend, FLAME.FlyBackend
  config :flame, FLAME.FlyBackend, cpu_kind: "performance", cpus: 4, memory_mb: 8192

  config :flame, FLAME.FlyBackend,
    token: System.get_env("FLY_API_TOKEN"),
    memory_mb: 8192,
    env: %{
      "BUCKET_MOUNT" => System.get_env("BUCKET_MOUNT"),
      "DATABASE_URL" => System.get_env("DATABASE_URL"),
      "LIVE_BEATS_GITHUB_CLIENT_ID" => System.fetch_env!("LIVE_BEATS_GITHUB_CLIENT_ID"),
      "LIVE_BEATS_GITHUB_CLIENT_SECRET" => System.get_env("LIVE_BEATS_GITHUB_CLIENT_SECRET")
    }

  config :live_beats, dns_cluster_query: System.get_env("DNS_CLUSTER_QUERY")

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []
  host = System.get_env("PHX_HOST") || "example.com"

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :live_beats, LiveBeats.Repo,
    migration_lock: false,
    timeout: 60_000,
    url: database_url,
    queue_interval: 60_000,
    socket_options: maybe_ipv6,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :live_beats, LiveBeatsWeb.Endpoint,
    url: [host: host, port: 80],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base,
    check_origin: false

  config :live_beats, :files,
    admin_usernames: ~w(chrismccord mrkurt),
    uploads_dir: Path.join(System.fetch_env!("BUCKET_MOUNT"), "/app/uploads"),
    host: [scheme: "https", host: host, port: 443],
    server_ip: System.get_env("LIVE_BEATS_SERVER_IP"),
    hostname: "livebeats.local",
    transport_opts: [inet6: true]

  config :live_beats, :github,
    client_id: System.fetch_env!("LIVE_BEATS_GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("LIVE_BEATS_GITHUB_CLIENT_SECRET")

  config :libcluster,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]
end
