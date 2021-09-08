defmodule LiveBeatsWeb.PageControllerTest do
  use LiveBeatsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "LiveBeats"
  end
end
