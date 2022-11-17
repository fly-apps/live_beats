defmodule LiveBeatsWeb.ProfileLive.UploadFormComponent do
  use LiveBeatsWeb, :live_component

  alias LiveBeats.{MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.ProfileLive.SongEntryComponent

  @max_songs 10

  @impl true
  def update(%{action: {:duration, entry_ref, result}}, socket) do
    case result do
      {:ok, %MP3Stat{} = stat} ->
        {:ok, put_stats(socket, entry_ref, stat)}

      {:error, _} ->
        {:ok, cancel_changeset_upload(socket, entry_ref, :not_accepted)}
    end
  end

  def update(%{song: song} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(changesets: %{}, error_messages: [])
     |> allow_upload(:mp3,
       song_id: song.id,
       auto_upload: true,
       progress: &handle_progress/3,
       accept: ~w(.mp3),
       max_entries: @max_songs,
       max_file_size: 20_000_000,
       chunk_size: 64_000 * 3
     )}
  end

  @impl true
  def handle_event("validate", %{"_target" => ["mp3"]}, socket) do
    {_done, in_progress} = uploaded_entries(socket, :mp3)

    new_socket =
      Enum.reduce(in_progress, socket, fn entry, acc -> put_new_changeset(acc, entry) end)

    {:noreply, drop_invalid_uploads(new_socket)}
  end

  def handle_event("validate", %{"songs" => params, "_target" => ["songs", _, _]}, socket) do
    {:noreply, apply_params(socket, params, :validate)}
  end

  def handle_event("save", %{"songs" => params}, socket) do
    socket = apply_params(socket, params, :insert)
    %{current_user: current_user} = socket.assigns
    changesets = socket.assigns.changesets

    if pending_stats?(socket) do
      {:noreply, socket}
    else
      case MediaLibrary.import_songs(current_user, changesets, &consume_entry(socket, &1, &2)) do
        {:ok, songs} ->
          {:noreply,
           socket
           |> put_flash(:info, "#{map_size(songs)} song(s) uploaded")
           |> push_patch(to: profile_path(current_user))}

        {:error, {failed_op, reason}} ->
          {:noreply, put_error(socket, {failed_op, reason})}
      end
    end
  end

  def handle_event("save", %{} = _params, socket) do
    {:noreply, socket}
  end

  defp pending_stats?(socket) do
    Enum.find(socket.assigns.changesets, fn {_ref, chset} -> !chset.changes[:duration] end)
  end

  defp consume_entry(socket, ref, store_func) when is_function(store_func) do
    {entries, []} = uploaded_entries(socket, :mp3)
    entry = Enum.find(entries, fn entry -> entry.ref == ref end)
    consume_uploaded_entry(socket, entry, fn meta -> {:ok, store_func.(meta.path)} end)
  end

  defp apply_params(socket, params, action) when action in [:validate, :insert] do
    Enum.reduce(params, socket, fn {ref, song_params}, acc ->
      new_changeset =
        acc
        |> get_changeset(ref)
        |> MediaLibrary.change_song(song_params)
        |> Map.put(:action, action)

      update_changeset(acc, new_changeset, ref)
    end)
  end

  defp get_changeset(socket, entry_ref) do
    case Enum.find(socket.assigns.changesets, fn {ref, _changeset} -> ref === entry_ref end) do
      {^entry_ref, changeset} -> changeset
      nil -> nil
    end
  end

  defp put_new_changeset(socket, entry) do
    cond do
      get_changeset(socket, entry.ref) ->
        socket

      Enum.count(socket.assigns.changesets) > @max_songs ->
        socket

      true ->
        attrs = MediaLibrary.parse_file_name(entry.client_name)
        changeset = MediaLibrary.change_song(%MediaLibrary.Song{}, attrs)

        update_changeset(socket, changeset, entry.ref)
    end
  end

  defp update_changeset(socket, %Ecto.Changeset{} = changeset, entry_ref) do
    update(socket, :changesets, &Map.put(&1, entry_ref, changeset))
  end

  defp drop_changeset(socket, entry_ref) do
    update(socket, :changesets, &Map.delete(&1, entry_ref))
  end

  defp handle_progress(:mp3, entry, socket) do
    SongEntryComponent.send_progress(entry)

    if entry.done? do
      async_calculate_duration(socket, entry)
    end

    {:noreply, put_new_changeset(socket, entry)}
  end

  defp async_calculate_duration(socket, %Phoenix.LiveView.UploadEntry{} = entry) do
    lv = self()

    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      Task.Supervisor.start_child(LiveBeats.TaskSupervisor, fn ->
        send_update(lv, __MODULE__,
          id: socket.assigns.id,
          action: {:duration, entry.ref, LiveBeats.MP3Stat.parse(path)}
        )
      end)

      {:postpone, :ok}
    end)
  end

  defp file_error(%{kind: :dropped} = assigns),
    do: ~H|<%= @label %>: dropped (exceeds limit of 10 files)|

  defp file_error(%{kind: :too_large} = assigns),
    do: ~H|<%= @label %>: larger than 10MB|

  defp file_error(%{kind: :not_accepted} = assigns),
    do: ~H|<%= @label %>: not a valid MP3 file|

  defp file_error(%{kind: :too_many_files} = assigns),
    do: ~H|too many files|

  defp file_error(%{kind: :songs_limit_exceeded} = assigns),
    do: ~H|You exceeded the limit of songs per account|

  defp file_error(%{kind: :invalid} = assigns),
    do: ~H|Something went wrong|

  defp file_error(%{kind: %Ecto.Changeset{}} = assigns),
    do: ~H|<%= @label %>: <%= translate_changeset_errors(@kind) %>|

  defp file_error(%{kind: {msg, opts}} = assigns) when is_binary(msg) and is_list(opts),
    do: ~H|<%= @label %>: <%= translate_error(@kind) %>|

  defp put_stats(socket, entry_ref, %MP3Stat{} = stat) do
    if changeset = get_changeset(socket, entry_ref) do
      case MediaLibrary.put_stats(changeset, stat) do
        {:ok, new_changeset} ->
          update_changeset(socket, new_changeset, entry_ref)

        {:error, %{duration: error}} ->
          cancel_changeset_upload(socket, entry_ref, error)
      end
    else
      socket
    end
  end

  defp drop_invalid_uploads(socket) do
    %{uploads: uploads} = socket.assigns

    Enum.reduce(Enum.with_index(uploads.mp3.entries), socket, fn {entry, i}, socket ->
      if i >= @max_songs do
        cancel_changeset_upload(socket, entry.ref, :dropped)
      else
        case upload_errors(uploads.mp3, entry) do
          [first | _] ->
            cancel_changeset_upload(socket, entry.ref, first)

          [] ->
            socket
        end
      end
    end)
  end

  defp cancel_changeset_upload(socket, entry_ref, reason) do
    entry = get_entry!(socket, entry_ref)

    socket
    |> cancel_upload(:mp3, entry.ref)
    |> drop_changeset(entry.ref)
    |> put_error({entry.client_name, reason})
  end

  defp get_entry!(socket, entry_ref) do
    Enum.find(socket.assigns.uploads.mp3.entries, fn entry -> entry.ref == entry_ref end) ||
      raise "no entry found for ref #{inspect(entry_ref)}"
  end

  defp put_error(socket, {label, msg}) do
    update(socket, :error_messages, &Enum.take(&1 ++ [{label, msg}], -10))
  end
end
