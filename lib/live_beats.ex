defmodule LiveBeats do
  @moduledoc """
  The main interface for shared functionality.
  """
  require Logger

  @doc """
  Looks up `Application` config or raises if keyspace is not configured.

  ## Examples

      config :live_beats, :files, [
        uploads_dir: Path.expand("../priv/uploads", __DIR__),
        host: [scheme: "http", host: "localhost", port: 4000],
      ]

      iex> LiveBeats.config([:files, :uploads_dir])
      iex> LiveBeats.config([:files, :host, :port])
  """
  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:live_beats, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{inspect(keyspace)}"
      end
    end)
  end

  @doc """
  Attaches a modules to another for listening of events.

  Events are executed in the caller's process. Accepts
  the `:to` option which a tuple of the form: {ContextModule, StructModule}

  You attached to conctext modules on a struct-by-struct basis for granular
  events. The struct module passed must implement a valid struct or an error
  is raised.

  Events that executed are sent to a `handle_execute/2`, callback, which the
  source module and executed event as arguments.

  ## Examples

      defmodule MyModule do
        def handle_execute({Accounts, %Accounts.Events.UpdateUpdated{user: user}}) do
          IO.inspect({:user_updated, user})
        end
      end

      iex> LiveBeats.attach(MyModule, to: {Accounts, Accounts.Events.UserUpdated})
      :ok

      iex> LiveBeats.execute(Accounts, %Accounts.Events.UserUpdated{user: new_user})
  """
  def attach(target_mod, opts) when is_atom(target_mod) do
    {src_mod, struct_mod} = Keyword.fetch!(opts, :to)
    _ = struct_mod.__struct__

    :ok =
      :telemetry.attach(target_mod, [src_mod, struct_mod], &__MODULE__.handle_execute/4, %{
        target: target_mod
      })
  end

  @doc """
  Executes an event from the context module with an event struct.

  Events are exected *in the caller's process*, for every attached listener.

  ## Examples

      iex> LiveBeats.attach(MyModule, to: {Accounts, Accounts.Events.UserUpdated})
      :ok

      iex> LiveBeats.execute(Accounts, %Accounts.Events.UserUpdated{user: new_user})
  """
  def execute(src_mod, event_struct) when is_struct(event_struct) do
    :telemetry.execute([src_mod, event_struct.__struct__], event_struct, %{})
  end

  @doc false
  def handle_execute([src_mod, event_mod], %event_mod{} = event_struct, _meta, %{target: target}) do
    try do
      target.handle_execute({src_mod, event_struct})
    catch
      kind, err ->
        Logger.error("""
        executing {#{inspect(src_mod)}, #{inspect(event_mod)}} failed with #{inspect(kind)}

            #{inspect(err)}
        """)
    end
  end
end
