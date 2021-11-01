defmodule LiveBeatsWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

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

  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-content",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-content",
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
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:confirm, fn -> nil end)
      |> assign_new(:cancel, fn -> nil end)
      |> assign_new(:return_to, fn -> nil end)

    ~H"""
    <div id={@id} class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"} aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div
          id={"#{@id}-content"}
          class={"#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle lg:ml-48 sm:max-w-2xl sm:w-full sm:p-6"}
          phx-window-keydown={hide_modal(@id)} phx-key="escape"
          phx-click-away={hide_modal(@id)}
        >
          <%= if @return_to do %>
            <%= live_redirect "close", to: @return_to, data: [modal_return: true], class: "hidden" %>
          <% end %>
          <div class="sm:flex sm:items-start">
            <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-green-100 sm:mx-0 sm:h-10 sm:w-10">
              <!-- Heroicon name: outline/plus -->
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full mr-12">
              <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                <%= render_slot(@title) %>
              </h3>
              <div class="mt-2">
                <p class="text-sm text-gray-500">
                  <%= render_slot(@inner_block) %>
                </p>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <%= if @confirm do %>
              <button type="button" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
                <%= render_slot(@confirm) %>
              </button>
            <% end %>
            <%= if @cancel do %>
              <button
                type="button"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
                phx-click={hide_modal(@id)}
              >
                <%= render_slot(@cancel) %>
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
      <div id="progress"
        class="bg-lime-500 dark:bg-lime-400 h-1.5 w-0"
        phx-hook="Progress"
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
            <%= for row <- @rows do %>
              <tr class="hover:bg-gray-50">
                <%= for {col, i} <- Enum.with_index(@col) do %>
                  <td class={"px-6 py-3 whitespace-nowrap text-sm font-medium text-gray-900 #{if i == 0, do: "max-w-0 w-full"}"}>
                    <div class="flex items-center space-x-3 lg:pl-2">
                      <%= if i == 0 do %>
                        <div class="flex-shrink-0 w-2.5 h-2.5 rounded-full bg-pink-600 mr-2" aria-hidden="true"></div>
                      <% end %>
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
end
