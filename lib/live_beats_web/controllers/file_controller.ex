defmodule LiveBeatsWeb.FileController do
  use LiveBeatsWeb, :controller

  alias LiveBeats.MediaLibrary

  def show(conn, %{"id" => filename_uuid, "token" => token}) do
    case Phoenix.Token.verify(conn, "file", token, max_age: :timer.minutes(10)) do
      {:ok, ^filename_uuid} -> do_send_file(conn, MediaLibrary.local_filepath(filename_uuid))
      {:ok, _} -> send_resp(conn, :unauthorized, "")
      {:error, _} -> send_resp(conn, :unauthorized, "")
    end
  end

  defp do_send_file(conn, path) do
    # accept-ranges headers required for chrome to seek via currentTime
    conn
    |> put_resp_header("content-type", "audio/mp3")
    |> put_resp_header("accept-ranges", "bytes")
    |> send_file(200, path)
  end
end
