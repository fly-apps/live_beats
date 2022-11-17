defmodule LiveBeatsWeb.Layouts do
  use LiveBeatsWeb, :html

  alias LiveBeatsWeb.Endpoint

  embed_templates "layouts/*"

  attr :id, :string
  attr :users, :list

  def sidebar_active_users(assigns) do
    ~H"""
    <div class="mt-8">
      <h3 class="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider" id={@id}>
        Active Users
      </h3>
      <div class="mt-1 space-y-1" role="group" aria-labelledby={@id}>
        <%= for user <- @users do %>
          <.link
            navigate={profile_path(user)}
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

  attr :id, :string
  attr :current_user, :any
  attr :active_tab, :atom

  def sidebar_nav_links(assigns) do
    ~H"""
    <div class="space-y-1">
      <%= if @current_user do %>
        <.link
          navigate={profile_path(@current_user)}
          class={
            "text-gray-700 hover:text-gray-900 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :profile, do: "bg-gray-200", else: "hover:bg-gray-50"}"
          }
          aria-current={if @active_tab == :profile, do: "true", else: "false"}
        >
          <.icon
            name={:music_note}
            outlined
            class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6"
          /> My Songs
        </.link>

        <.link
          navigate={Routes.settings_path(Endpoint, :edit)}
          class={
            "text-gray-700 hover:text-gray-900 group flex items-center px-2 py-2 text-sm font-medium rounded-md #{if @active_tab == :settings, do: "bg-gray-200", else: "hover:bg-gray-50"}"
          }
          aria-current={if @active_tab == :settings, do: "true", else: "false"}
        >
          <.icon
            name={:adjustments}
            outlined
            class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6"
          /> Settings
        </.link>
      <% else %>
        <.link
          navigate={Routes.sign_in_path(Endpoint, :index)}
          class="text-gray-700 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md"
        >
          <svg
            class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
            >
            </path>
          </svg>
          Sign in
        </.link>
      <% end %>
    </div>
    """
  end

  attr :id, :string
  attr :current_user, :any
  def sidebar_account_dropdown(assigns) do
    ~H"""
    <.dropdown id={@id}>
      <:img src={@current_user.avatar_url} />
      <:title><%= @current_user.name %></:title>
      <:subtitle>@<%= @current_user.username %></:subtitle>
      <:link navigate={profile_path(@current_user)}>View Profile</:link>
      <:link navigate={Routes.settings_path(Endpoint, :edit)}>Settings</:link>
      <:link href={Routes.o_auth_callback_path(Endpoint, :sign_out)} method={:delete}>Sign out</:link>
    </.dropdown>
    """
  end
end
