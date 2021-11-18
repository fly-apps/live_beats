defmodule LiveBeatsWeb.LayoutView do
  use LiveBeatsWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def sidebar_active_users(assigns) do
    ~H"""
    <div class="mt-8">
      <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider" id={@id}>
        Active Users
      </h3>
      <div class="mt-1 space-y-1" role="group" aria-labelledby={@id}>
        <%= for user <- @users do %>
          <.link redirect_to={profile_path(user)}
            class="group flex items-center px-3 py-2 text-base leading-5 font-medium text-gray-600 rounded-md hover:text-gray-900 hover:bg-gray-50"
          >
            <span class="w-2.5 h-2.5 mr-4 bg-indigo-500 rounded-full" aria-hidden="true"></span>
            <span class="truncate">
              <%= user.username %>
            </span>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  def sidebar_nav_links(assigns) do
    ~H"""
    <div class="space-y-1">
      <%= if @current_user do %>
        <.link
          redirect_to={profile_path(@current_user)}
          class="text-gray-700 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md"
        >
          <.icon name={:music_note} outlined class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6"/>
          My Songs
        </.link>

        <.link
          redirect_to={Routes.settings_path(LiveBeatsWeb.Endpoint, :edit)}
          class="text-gray-700 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md"
        >
          <.icon name={:adjustments} outlined class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6"/>
          Settings
        </.link>
      <% else %>
        <.link redirect_to={Routes.sign_in_path(LiveBeatsWeb.Endpoint, :index)}
          class="text-gray-700 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md"
        >
          <svg class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6"
            xmlns="http://www.w3.org/2000/svg" fill="none"
            viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          Sign in
        </.link>
      <% end %>
    </div>
    """
  end

  def sidebar_account_dropdown(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class="px-3 mt-6 relative inline-block text-left">
      <div>
        <button id={"#{@id}-menu"} type="button" phx-hook="Menu" data-active-class="bg-gray-100"
          class="group w-full bg-gray-100 rounded-md px-3.5 py-2 text-sm text-left font-medium text-gray-700 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-purple-500"
          phx-click={show_dropdown("##{@id}-dropdown")}>
          <span class="flex w-full justify-between items-center">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <img class="w-10 h-10 bg-gray-300 rounded-full flex-shrink-0"
                src={@current_user.avatar_url}
                alt="">
              <span class="flex-1 flex flex-col min-w-0">
                <span class="text-gray-900 text-sm font-medium truncate"><%= @current_user.name %></span>
                <span class="text-gray-500 text-sm truncate">@<%= @current_user.username %></span>
              </span>
            </span>
            <svg class="flex-shrink-0 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"
              fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                clip-rule="evenodd"></path>
            </svg>
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 mx-3 origin-top absolute right-0 left-0 mt-1 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-200"
        role="menu"
        aria-labelledby={"#{@id}-menu"}
        phx-update="ignore"
      >
        <div class="py-1" role="none">
          <.link
            role="menuitem"
            redirect_to={profile_path(@current_user)}
            class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          >View Profile</.link>
          <.link
            role="menuitem"
            redirect_to={Routes.settings_path(LiveBeatsWeb.Endpoint, :edit)}
            class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" role="menuitem"
          >Settings</.link>
        </div>

        <div class="py-1" role="none">
          <.link
            role="menuitem"
            href={Routes.o_auth_callback_path(LiveBeatsWeb.Endpoint, :sign_out)}
            method={:delete}
            role="menuitem"
            class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          >Sign out</.link>
        </div>
      </div>
    </div>
    """
  end
end
