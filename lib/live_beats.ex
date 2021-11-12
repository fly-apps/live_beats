defmodule LiveBeats do
  require Logger

  def attach(target_mod, opts) when is_atom(target_mod) do
    {src_mod, struct_mod} = Keyword.fetch!(opts, :to)
    _ = struct_mod.__struct__

    :ok =
      :telemetry.attach(target_mod, [src_mod, struct_mod], &__MODULE__.handle_execute/4, %{
        target: target_mod
      })
  end

  def execute(src_mod, event_struct) when is_struct(event_struct) do
    :telemetry.execute([src_mod, event_struct.__struct__], event_struct, %{})
  end

  @doc false
  def handle_execute([src_mod, event_mod], %event_mod{} = event_struct, _meta, %{target: target}) do
    try do
      target.handle_execute({src_mod, event_struct})
    catch
      kind, err ->
        Logger.error """
        executing {#{inspect(src_mod)}, #{inspect(event_mod)}} failed with #{inspect(kind)}

            #{inspect(err)}
        """
    end
  end
end
