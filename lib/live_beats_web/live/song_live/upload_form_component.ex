defmodule LiveBeatsWeb.SongLive.UploadFormComponent do
  use LiveBeatsWeb, :live_component

  alias LiveBeats.{MediaLibrary, MP3Stat}
  alias LiveBeatsWeb.SongLive.SongEntry

  @max_songs 10

  @impl true
  def update(%{action: {:duration, entry_ref, result}}, socket) do
    case result do
      {:ok, %MP3Stat{} = stat} ->
        {:ok, put_stats(socket, entry_ref, stat)}

      _ ->
        {:ok, cancel_upload(socket, :mp3, entry_ref)}
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
       max_file_size: 20_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"_target" => ["mp3"]}, socket) do
    {:noreply, drop_invalid_uploads(socket)}
  end

  def handle_event("validate", %{"songs" => params, "_target" => ["songs", _, _]}, socket) do
    {:noreply, apply_params(socket, params, :validate)}
  end

  def handle_event("save", %{"songs" => params}, socket) do
    socket = apply_params(socket, params, :insert)
    %{current_user: current_user} = socket.assigns
    changesets = socket.assigns.changesets

    case MediaLibrary.import_songs(current_user, changesets, &consume_entry(socket, &1, &2)) do
      {:ok, songs} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{map_size(songs)} song(s) uploaded")
         |> push_redirect(to: Routes.song_index_path(socket, :index))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "There were problems uploading your songs")}
    end
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
        |> Ecto.Changeset.apply_changes()
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
    if get_changeset(socket, entry.ref) do
      socket
    else
      if Enum.count(socket.assigns.changesets) > @max_songs do
        raise RuntimeError, "file upload limited exceeded"
      end

      attrs = MediaLibrary.parse_file_name(entry.client_name)
      changeset = MediaLibrary.change_song(%MediaLibrary.Song{}, attrs)

      update_changeset(socket, changeset, entry.ref)
    end
  end

  defp update_changeset(socket, %Ecto.Changeset{} = changeset, entry_ref) do
    update(socket, :changesets, &Map.put(&1, entry_ref, changeset))
  end

  defp handle_progress(:mp3, entry, socket) do
    send_update(SongEntry, id: entry.ref, progress: entry.progress)

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

  defp file_error(%{kind: :dropped} = assigns), do: ~H|dropped (exceeds limit of 10 files)|
  defp file_error(%{kind: :too_large} = assigns), do: ~H|larger than 10MB|
  defp file_error(%{kind: :not_accepted} = assigns), do: ~H|not a valid MP3 file|
  defp file_error(%{kind: :too_many_files} = assigns), do: ~H|too many files|

  defp put_stats(socket, entry_ref, %MP3Stat{} = stat) do
    if changeset = get_changeset(socket, entry_ref) do
      update_changeset(socket, MediaLibrary.put_stats(changeset, stat), entry_ref)
    else
      socket
    end
  end

  defp drop_invalid_uploads(socket) do
    %{uploads: uploads} = socket.assigns

    {new_socket, error_messages, _index} =
      Enum.reduce(uploads.mp3.entries, {socket, [], 0}, fn entry, {socket, msgs, i} ->
        if i >= @max_songs do
          {cancel_upload(socket, :mp3, entry.ref), [{entry.client_name, :dropped} | msgs], i + 1}
        else
          case upload_errors(uploads.mp3, entry) do
            [first | _] ->
              {cancel_upload(socket, :mp3, entry.ref), [{entry.client_name, first} | msgs], i + 1}

            [] ->
              {socket, msgs, i + 1}
          end
        end
      end)

    assign(new_socket, error_messages: error_messages)
  end
end
