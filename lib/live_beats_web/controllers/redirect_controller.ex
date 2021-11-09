defmodule LiveBeatsWeb.RedirectController do
  use LiveBeatsWeb, :controller

  def redirect_authenticated(conn, _) do
    if conn.assigns.current_user do
      LiveBeatsWeb.UserAuth.redirect_if_user_is_authenticated(conn, [])
    else
      redirect(conn, to: Routes.sign_in_path(conn, :index))
    end
  end
end
