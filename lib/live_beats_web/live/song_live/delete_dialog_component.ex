defmodule LiveBeatsWeb.SongLive.DeleteDialogComponent do
  use LiveBeatsWeb, :live_component

  alias LiveBeats.MediaLibrary

  def send_show(%MediaLibrary.Song{} = song) do
    send_update(__MODULE__, id: "delete-modal", show: song)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="delete-modal"
        loading={is_nil(@song.id)}
        on_confirm={JS.push("confirm-delete", value: %{id: @song.id}) |> hide("#song-#{@song.id}")}
        on_cancel={JS.push("cancel", target: @myself)}>

        Are you sure you want to delete "<%= @song.title %>"?

        <:cancel>Cancel</:cancel>
        <:confirm>Delete</:confirm>
      </.modal>
    </div>
    """
  end

  @impl true
  def update(%{show: %MediaLibrary.Song{} = song}, socket) do
    {:ok, assign(socket, song: song)}
  end

  def update(%{} = _assigns, socket) do
    {:ok, assign_defaults(socket)}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    IO.inspect({:cancel})
    {:noreply, assign_defaults(socket)}
  end

  defp assign_defaults(socket) do
    assign(socket, song: %MediaLibrary.Song{})
  end
end
