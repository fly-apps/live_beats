defmodule LiveBeatsWeb.SettingsLive do
  use LiveBeatsWeb, :live_view

  alias LiveBeats.Accounts

  def render(assigns) do
    ~H"""
    <.title_bar>
      Profile Settings
    </.title_bar>

    <div class="max-w-3xl px-4 mx-auto mt-6">
      <.form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        class="space-y-8 divide-y divide-gray-200"
      >
        <div class="space-y-8 divide-y divide-gray-200">
          <div>
            <div>
              <p class="mt-1 text-sm text-gray-500">
                This information will be displayed publicly so be careful what you share.
              </p>
            </div>

            <div class="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <div class="sm:col-span-4">
                <label for="username" class="block text-sm font-medium text-gray-700">
                  Username
                </label>
                <div class="mt-1 flex rounded-md shadow-sm">
                  <span class="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm">
                    <%= URI.parse(LiveBeatsWeb.Endpoint.url()).host %>/
                  </span>
                  <%= text_input(f, :username,
                    class:
                      "flex-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full min-w-0 rounded-none rounded-r-md sm:text-sm border-gray-300"
                  ) %>
                  <.error
                    field={:username}
                    input_name="user[username]"
                    errors={@changeset.errors}
                    class="pt-2 pl-4 pr-4 ml-2 text-center"
                  />
                </div>
              </div>

              <div class="sm:col-span-4">
                <label for="username" class="block text-sm font-medium text-gray-700">
                  Email (from GitHub)
                </label>
                <div class="mt-1 flex rounded-md shadow-sm">
                  <%= text_input(f, :email,
                    disabled: true,
                    class:
                      "flex-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full min-w-0 rounded-md sm:text-sm border-gray-300 bg-gray-50"
                  ) %>
                </div>
              </div>

              <div class="sm:col-span-4">
                <label for="about" class="block text-sm font-medium text-gray-700">
                  Profile Tagline
                </label>
                <div class="mt-1">
                  <%= text_input(f, :profile_tagline,
                    class:
                      "flex-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full min-w-0 rounded-md sm:text-sm border-gray-300"
                  ) %>
                  <.error
                    field={:profile_tagline}
                    input_name="user[profile_tagline]"
                    errors={@changeset.errors}
                    class="pt-2 pl-4 pr-4 ml-2 text-center"
                  />
                </div>
                <p class="text-sm text-gray-500">Write a short tagline for your beats page.</p>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-5">
          <div class="flex justify-end">
            <button
              type="submit"
              class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Save
            </button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_settings(socket.assigns.current_user, %{})
    {:ok, assign(socket, changeset: changeset)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset = Accounts.change_settings(socket.assigns.current_user, params)
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_public_settings(socket.assigns.current_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> put_flash(:info, "settings updated!")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
