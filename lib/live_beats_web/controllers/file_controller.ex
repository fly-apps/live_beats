defmodule LiveBeatsWeb.FileController do
  use LiveBeatsWeb, :controller

  alias LiveBeats.MediaLibrary

  def show(conn, %{"id" => filename_uuid, "token" => token}) do
    case Phoenix.Token.verify(conn, "file", token, max_age: :timer.minutes(10)) do
      {:ok, ^filename_uuid} -> send_file(conn, 200, MediaLibrary.local_filepath(filename_uuid))
      {:ok, _} -> send_resp(conn, :unauthorized, "")
      {:error, _} -> send_resp(conn, :unauthorized, "")
      end
  end
end
