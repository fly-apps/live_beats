defmodule LiveBeatsWeb.PageController do
  use LiveBeatsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
