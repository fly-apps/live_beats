defmodule LiveBeatsWeb.HomeLive do
  use LiveBeatsWeb, :live_view

  # alias LiveBeats.MediaLibrary

  def render(assigns) do
    ~H"""
    <.title_bar>
      LiveBeats - Chill

      <:actions>
        <.button>Share</.button>
        <.button primary phx-click={show_modal("add-songs")}>Add Songs</.button>
      </:actions>
    </.title_bar>

    <.modal id="add-songs">
      <:title>Add Songs</:title>
      a modal
      <:cancel>Close</:cancel>
      <:confirm>Add</:confirm>
    </.modal>
    <!-- users -->
    <div class="px-4 mt-6 sm:px-6 lg:px-8">
      <h2 class="text-gray-500 text-xs font-medium uppercase tracking-wide">Who's Here</h2>
      <ul role="list" class="grid grid-cols-1 gap-4 sm:gap-6 sm:grid-cols-2 xl:grid-cols-4 mt-3" x-max="1">

        <li class="relative col-span-1 flex shadow-sm rounded-md">
          <div
            class="flex-shrink-0 flex items-center justify-center w-16 bg-pink-600 text-white text-sm font-medium rounded-l-md">
            CM
          </div>
          <div
            class="flex-1 flex items-center justify-between border-t border-r border-b border-gray-200 bg-white rounded-r-md truncate">
            <div class="flex-1 px-4 py-2 text-sm truncate">
              <a href="#" class="text-gray-900 font-medium hover:text-gray-600">
                Chris
              </a>
              <p class="text-gray-500">5 songs</p>
            </div>
          </div>
        </li>

        <li class="relative col-span-1 flex shadow-sm rounded-md">
          <div
            class="flex-shrink-0 flex items-center justify-center w-16 bg-purple-600 text-white text-sm font-medium rounded-l-md">
            KM
          </div>
          <div
            class="flex-1 flex items-center justify-between border-t border-r border-b border-gray-200 bg-white rounded-r-md truncate">
            <div class="flex-1 px-4 py-2 text-sm truncate">
              <a href="#" class="text-gray-900 font-medium hover:text-gray-600">
                Kurt
              </a>
              <p class="text-gray-500">1 song</p>
            </div>
          </div>
        </li>

        <li class="relative col-span-1 flex shadow-sm rounded-md">
          <div
            class="flex-shrink-0 flex items-center justify-center w-16 bg-green-600 text-white text-sm font-medium rounded-l-md">
            JV
          </div>
          <div
            class="flex-1 flex items-center justify-between border-t border-r border-b border-gray-200 bg-white rounded-r-md truncate">
            <div class="flex-1 px-4 py-2 text-sm truncate">
              <a href="#" class="text-gray-900 font-medium hover:text-gray-600">
                José
              </a>
              <p class="text-gray-500">1 song</p>
            </div>
          </div>
        </li>
      </ul>
    </div>

    <!-- Projects list (only on smallest breakpoint) -->
    <div class="mt-10 sm:hidden">
      <div class="px-4 sm:px-6">
        <h2 class="text-gray-500 text-xs font-medium uppercase tracking-wide">Projects</h2>
      </div>
      <ul role="list" class="mt-3 border-t border-gray-200 divide-y divide-gray-100">

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-pink-600" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                GraphQL API
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Engineering</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-purple-600" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                New Benefits Plan
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Human Resources</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-yellow-500" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Onboarding Emails
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Customer Success</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-green-500" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                iOS App
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Engineering</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-pink-600" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Marketing Site Redesign
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Engineering</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-purple-600" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Hire CFO
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Human Resources</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-yellow-500" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Android App
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Engineering</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-green-500" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                New Customer Portal
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Engineering</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-pink-600" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Co-op Program
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Human Resources</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-purple-600" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Implement NPS
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Customer Success</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-yellow-500" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Employee Recognition Program
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Human Resources</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

        <li>
          <a href="#" class="group flex items-center justify-between px-4 py-4 hover:bg-gray-50 sm:px-6">
            <span class="flex items-center truncate space-x-3">
              <span class="w-2.5 h-2.5 flex-shrink-0 rounded-full bg-green-500" aria-hidden="true"></span>
              <span class="font-medium truncate text-sm leading-6">
                Open Source Web Client
                <!-- space -->
                <span class="truncate font-normal text-gray-500">in Engineering</span>
              </span>
            </span>
            <svg class="ml-4 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              x-description="Heroicon name: solid/chevron-right" xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"></path>
            </svg>
          </a>
        </li>

      </ul>
    </div>

    <!-- Songs table (small breakpoint and up) -->
    <.table rows={@songs}>
      <:col let={song} label="Song">
        <%= song.title %>
      </:col>
      <:col let={song} label="Artist">
        <%= song.artist %>
      </:col>
      <:col let={song} label="Time">
        <%= song.duration %>
      </:col>
      <:col label=""></:col>
    </.table>
    """
  end

  def mount(_parmas, _session, socket) do
    {:ok, assign(socket, :songs, fetch_songs(socket))}
  end

  defp fetch_songs(_socket) do
    []
  end
end
