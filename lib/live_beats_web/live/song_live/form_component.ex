defmodule LiveBeatsWeb.SongLive.FormComponent do
  use LiveBeatsWeb, :live_component

  alias LiveBeats.{MediaLibrary, ID3}

  @impl true
  def update(%{song: song} = assigns, socket) do
    changeset = MediaLibrary.change_song(song)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(changeset: changeset, tmp_path: nil)
     |> allow_upload(:mp3,
       auto_upload: true,
       progress: &handle_progress/3,
       accept: ~w(.mp3),
       max_entries: 1,
       max_file_size: 20_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"song" => song_params}, socket) do
    changeset =
      socket.assigns.song
      |> MediaLibrary.change_song(song_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"song" => song_params}, socket) do
    IO.inspect({:save, song_params})
    save_song(socket, socket.assigns.action, song_params)
  end

  defp save_song(socket, :edit, song_params) do
    case MediaLibrary.update_song(socket.assigns.song, song_params) do
      {:ok, _song} ->
        {:noreply,
         socket
         |> put_flash(:info, "Song updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_song(socket, :new, song_params) do
    case MediaLibrary.create_song(song_params) do
      {:ok, _song} ->
        {:noreply,
         socket
         |> put_flash(:info, "Song created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp handle_progress(:mp3, entry, socket) do
    changeset = socket.assigns.changeset

    if entry.done? do
      new_socket =
        consume_uploaded_entry(socket, entry, fn %{} = meta ->
          case ID3.parse(meta.path) do
            {:ok, %ID3{} = id3} ->
              new_changeset =
                changeset
                |> Ecto.Changeset.put_change(:title, id3.title)
                |> Ecto.Changeset.put_change(:artist, id3.artist)

              socket
              |> assign(changeset: new_changeset)
              |> put_tmp_mp3(meta.path)

            {:error, _} ->
              put_tmp_mp3(socket, meta.path)
          end
        end)

      {:noreply, new_socket}
    else
      {:noreply, socket}
    end
  end

  defp put_tmp_mp3(socket, path) do
    if socket.assigns.tmp_path, do: File.rm!(socket.assigns.tmp_path)
    {:ok, tmp_path} = Plug.Upload.random_file("temp_mp3")
    File.cp!(path, tmp_path)
    assign(socket, tmp_path: tmp_path)
  end


  defp file_error(%{kind: :too_large} = assigns), do: ~H|larger than 10MB|
  defp file_error(%{kind: :not_accepted} = assigns), do: ~H|not a valid MP3 file|
end
