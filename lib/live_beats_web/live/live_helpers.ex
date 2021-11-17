defmodule LiveBeatsWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias LiveBeatsWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

  alias LiveBeats.Accounts
  alias LiveBeats.MediaLibrary

  def profile_path(%Accounts.User{} = current_user) do
    Routes.song_index_path(LiveBeatsWeb.Endpoint, :index, current_user.username)
  end

  def profile_path(%MediaLibrary.Profile{} = profile) do
    Routes.song_index_path(LiveBeatsWeb.Endpoint, :index, profile.username)
  end

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-green-50 p-4 top-0 right-0 w-96 fade-in-scale"
        phx-click="lv:clear-flash"
        phx-value-key="error"
        phx-remove={JS.remove_class("fade-in-scale", to: "#flash") |> hide("#flash")}
        phx-hook="Flash"
      >
        <div class="flex">
          <div class="flex-shrink-0">
            <.icon name={:check_circle} solid />
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-red-800">
              <%= live_flash(@flash, @kind) %>
            </p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button type="button" class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50 focus:ring-red-600">
                <.icon name={:x} solid />
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-green-50 p-4 fixed top-1 right-1 w-96 fade-in-scale"
        phx-click="lv:clear-flash"
        phx-value-key="info"
        phx-remove={JS.remove_class("fade-in-scale", to: "#flash") |> hide("#flash")}
        phx-hook="Flash"
      >
        <div class="flex">
          <div class="flex-shrink-0">
            <.icon name={:check_circle} solid />
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-green-800">
              <%= live_flash(@flash, @kind) %>
            </p>
          </div>
          <div class="ml-auto pl-3">
            <div class="-mx-1.5 -my-1.5">
              <button type="button" class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600">
                <.icon name={:x} solid />
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def spinner(assigns) do
    ~H"""
    <svg class="inline-block animate-spin h-2.5 w-2.5 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    """
  end

  def icon(assigns) do
    assigns =
      assigns
      |> assign_new(:outlined, fn -> false end)
      |> assign_new(:class, fn -> "w-4 h-4 inline-block" end)
      |> assign_new(:alt, fn -> "" end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons.Outline, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% else %>
      <%= apply(Heroicons.Solid, @name, [assigns_to_attributes(assigns, [:outlined, :name])]) %>
    <% end %>
    """
  end

  def link(%{redirect_to: to} = assigns) do
    opts = assigns |> assigns_to_attributes() |> Keyword.put(:to, to)
    assigns = assign(assigns, :opts, opts)

    ~H"""
    <%= live_redirect @opts do %><%= render_slot(@inner_block) %><% end %>
    """
  end

  def link(%{patch_to: to} = assigns) do
    opts = assigns |> assigns_to_attributes() |> Keyword.put(:to, to)
    assigns = assign(assigns, :opts, opts)

    ~H"""
    <%= live_patch @opts do %><%= render_slot(@inner_block) %><% end %>
    """
  end

  def link(%{} = assigns) do
    opts = assigns |> assigns_to_attributes() |> Keyword.put(:to, assigns[:href] || "#")
    assigns = assign(assigns, :opts, opts)

    ~H"""
    <%= Phoenix.HTML.Link.link @opts do %><%= render_slot(@inner_block) %><% end %>
    """
  end

  def show_mobile_sidebar(js \\ %JS{}) do
    js
    |> JS.show(to: "#mobile-sidebar-container", transition: "fade-in")
    |> JS.show(
      to: "#mobile-sidebar",
      display: "flex",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
    )
  end

  def hide_mobile_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-sidebar-container", transition: "fade-out")
    |> JS.hide(
      to: "#mobile-sidebar",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_dropdown(to) do
    JS.show(
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
  end

  def hide_dropdown(to) do
    JS.hide(
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> js_exec("##{id}-confirm", "focus", [])
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  def modal(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:patch_to, fn -> nil end)
      |> assign_new(:redirect_to, fn -> nil end)
      |> assign_new(:on_cancel, fn -> %JS{} end)
      |> assign_new(:on_confirm, fn -> %JS{} end)
      # slots
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:confirm, fn -> [] end)
      |> assign_new(:cancel, fn -> [] end)
      |> assign_rest(~w(id show patch_to redirect_to on_cancel on_confirm title confirm cancel)a)

    ~H"""
    <div id={@id} class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"} aria-labelledby="modal-title" role="dialog" aria-modal="true" {@rest}>
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div
          id={"#{@id}-container"}
          class={"#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-xl sm:w-full sm:p-6"}
          phx-window-keydown={hide_modal(@on_cancel, @id)} phx-key="escape"
          phx-click-away={hide_modal(@on_cancel, @id)}
        >
          <%= if @patch_to do %>
            <.link patch_to={@patch_to} data-modal-return class="hidden"></.link>
          <% end %>
          <%= if @redirect_to do %>
            <.link redirect_to={@redirect_to} data-modal-return class="hidden"></.link>
          <% end %>
          <div class="sm:flex sm:items-start">
            <div class={"mx-auto flex-shrink-0 flex items-center justify-center h-8 w-8 rounded-full bg-purple-100 sm:mx-0"}>
              <!-- Heroicon name: outline/plus -->
              <.icon name={:information_circle} outlined class="h-6 w-6 text-purple-600"/>
            </div>
            <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full mr-12">
              <h3 class="text-lg leading-6 font-medium text-gray-900" id={"#{@id}-title"}>
                <%= render_slot(@title) %>
              </h3>
              <div class="mt-2">
                <p id={"#{@id}-content"} class={"text-sm text-gray-500"}>
                  <%= render_slot(@inner_block) %>
                </p>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <%= for confirm <- @confirm do %>
              <button
                id={"#{@id}-confirm"}
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
                phx-click={@on_confirm}
                phx-disable-with
                tabindex="1"
                {assigns_to_attributes(confirm)}
              >
                <%= render_slot(confirm) %>
              </button>
            <% end %>
            <%= for cancel <- @cancel do %>
              <button
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
                phx-click={hide_modal(@on_cancel, @id)}
                tabindex="2"
                {assigns_to_attributes(cancel)}
              >
                <%= render_slot(cancel) %>
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def progress_bar(assigns) do
    assigns =
      assigns
      |> assign_new(:min, fn -> 0 end)
      |> assign_new(:max, fn -> 100 end)
      |> assign_new(:value, fn -> assigns[:min] || 0 end)

    ~H"""
    <div class="bg-gray-200 flex-auto dark:bg-black rounded-full overflow-hidden" phx-update="ignore">
      <div
        id={@id}
        class="bg-lime-500 dark:bg-lime-400 h-1.5 w-0"
        data-min={@min}
        data-max={@max}
        data-val={@value}>
      </div>
    </div>
    """
  end

  def title_bar(assigns) do
    assigns = assign_new(assigns, :actions, fn -> [] end)

    ~H"""
    <!-- Page title & actions -->
    <div class="border-b border-gray-200 px-4 py-4 sm:flex sm:items-center sm:justify-between sm:px-6 lg:px-8 h-16">
      <div class="flex-1 min-w-0">
        <h1 class="text-lg font-medium leading-6 text-gray-900 sm:truncate">
          <%= render_slot(@inner_block) %>
        </h1>
      </div>
      <div class="mt-4 flex sm:mt-0 sm:ml-4">
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end

  def button(%{patch_to: _} = assigns) do
    assigns = assign_new(assigns, :primary, fn -> false end)

    ~H"""
    <%= if @primary do %>
      <%= live_patch to: @patch_to, class: "order-0 inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 sm:order-1 sm:ml-3" do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    <% else %>
      <%= live_patch to: @patch_to, class: "order-1 inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 sm:order-0 sm:ml-0 lg:ml-3" do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    <% end %>
    """
  end

  def button(%{} = assigns) do
    assigns =
      assigns
      |> assign_new(:primary, fn -> false end)
      |> assign(:rest, assigns_to_attributes(assigns))

    ~H"""
    <%= if @primary do %>
      <button type="button" class="order-0 inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 sm:order-1 sm:ml-3" {@rest}>
        <%= render_slot(@inner_block) %>
      </button>
    <% else %>
      <button type="button" class="order-1 inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 sm:order-0 sm:ml-0 lg:ml-3" {@rest}>
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  def table(assigns) do
    assigns =
      assigns
      |> assign_new(:row_id, fn -> false end)
      |> assign(:col, for(col <- assigns.col, col[:if] != false, do: col))

    ~H"""
    <div class="hidden mt-8 sm:block">
      <div class="align-middle inline-block min-w-full border-b border-gray-200">
        <table class="min-w-full">
          <thead>
            <tr class="border-t border-gray-200">
              <%= for col <- @col do %>
                <th
                  class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <span class="lg:pl-2"><%= col.label %></span>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-100">
            <%= for {row, i} <- Enum.with_index(@rows) do %>
              <tr id={@row_id && @row_id.(row)} class="hover:bg-gray-50">
                <%= for col <- @col do %>
                  <td class={"px-6 py-3 whitespace-nowrap text-sm font-medium text-gray-900 #{if i == 0, do: "max-w-0 w-full"} #{col[:class]}"}>
                    <div class="flex items-center space-x-3 lg:pl-2">
                      <%= render_slot(col, row) %>
                    </div>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def live_table(assigns) do
    assigns =
      assigns
      |> assign_new(:row_id, fn -> false end)
      |> assign_new(:active_id, fn -> nil end)
      |> assign(:col, for(col <- assigns.col, col[:if] != false, do: col))

    ~H"""
    <div class="hidden mt-8 sm:block">
      <div class="align-middle inline-block min-w-full border-b border-gray-200">
        <table class="min-w-full">
          <thead>
            <tr class="border-t border-gray-200">
              <%= for col <- @col do %>
                <th
                  class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <span class="lg:pl-2"><%= col.label %></span>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-100">
            <%= for {row, i} <- Enum.with_index(@rows) do %>
              <.live_component
                module={@module}
                id={@row_id.(row)}
                row={row} col={@col}
                index={i}
                active_id={@active_id}
                class="hover:bg-gray-50"
              />
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.

      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end

  defp assign_rest(assigns, exclude) do
    assign(assigns, :rest, assigns_to_attributes(assigns, exclude))
  end
end
