defmodule TwoElevenWeb.UI do
  @moduledoc """
  Common UI components.

  A collection of common UI common used across the project. **NOTE** that these
  components us _Phoenix Live View_ features, so they cannot be used safely in
  classic _Phoenix_ components.

  Aliases by default (as `UI`) when using `:live_view` and `:live_component`.
  """

  use TwoElevenWeb, :component

  @doc "A common button"
  @spec button(map()) :: Rendered.t()
  def button(assigns = %{action: "patch", to: _target}) do
    assigns =
      assigns
      |> assign(:replace, assigns[:replace] == "true")
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <%= live_patch to: @to, replace: @replace, class: "button #{@class}" do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  @doc "A modal component"
  @spec modal(map()) :: Rendered.t()
  def modal(assigns) do
    assigns =
      assigns
      |> assign(:content_id, "#{assigns.id}-content")
      |> assign(:close_id, "#{assigns.id}-close")
      |> assign_new(:title, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)

    ~H"""
    <div
      id={@id}
      role="dialog"
      aria-modal="true"
      class="animate-fade-in bg-stone-900/30 fixed inset-0 opacity-100 overflow-auto sm:flex sm:items-center sm:justify-center z-50"
      phx-remove={modal_hide(@id, @content_id)}
    >
      <div
        id={@content_id}
        class="bg-stone-200 dark:bg-stone-800 rounded-lg border-2  border-stone-500 flex flex-col min-h-full motion-safe:animate-fade-in-scale p-2 panel sm:min-h-0 space-y-4"
        phx-click-away={JS.dispatch("click", to: id_ref(@close_id))}
        phx-window-keydown={JS.dispatch("click", to: id_ref(@close_id))}
        phx-key="escape"
      >
        <div class="flex items-end justify-between space-x-8 w-full">
          <%= if @title do %>
            <span class="font-bold leading-none text-lg"><%= @title %></span>
          <% end %>
          <%= live_patch id: assigns.close_id, to: assigns.return_to, class: "link", phx_click: modal_hide(@id, @content_id) do %>
            ✕
          <% end %>
        </div>
        <div><%= render_slot(@inner_block) %></div>
      </div>
    </div>
    """
  end

  @spec modal_hide(struct(), binary(), binary()) :: struct()
  defp modal_hide(js \\ %JS{}, modal_id, content_id) do
    js
    |> JS.hide(to: id_ref(modal_id), transition: "animate-fade-out")
    |> JS.hide(to: id_ref(content_id), transition: "motion-safe:animate-fade-out-scale")
  end

  @doc "Main shared header"
  @spec header(map()) :: Rendered.t()
  def header(assigns) do
    assigns = assign_new(assigns, :player, fn -> nil end)

    ~H"""
    <header class="bg-stone-100 border-b-2 border-stone-200 dark:bg-stone-900 dark:border-stone-800 flex items-center justify-between md:px-4 min-h-[min(10vh,64px)] p-2 shrink-0">
      <%= live_redirect to: Routes.games_path(TwoElevenWeb.Endpoint, :index), replace: true, class: "dark:text-orange-700 font-bold leading-none text-orange-500 text-xl" do %>
        <h1>2<sup>11</sup></h1>
      <% end %>

      <%= if @player do %>
        <.player_tag name={@player.name} emoji={@player.emoji} class="text-xl" />
      <% end %>
    </header>
    """
  end

  @doc "Displays information about a player"
  @spec player_tag(map()) :: Rendered.t()
  def player_tag(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:hide_name, fn -> "false" end)

    ~H"""
    <div class={"flex inline-block items-center space-x-2 #{@class}"}>
      <div
        title={"Player: #{@name}"}
        class="aspect-square bg-stone-200 border-2 border-stone-500 cursor-help dark:bg-stone-800 leading-none p-1 rounded-full"
      >
        <%= @emoji %>
      </div>
      <%= unless @hide_name == "true" do %>
        <span class="font-medium text-stone-500 whitespace-nowrap"><%= @name %></span>
      <% end %>
    </div>
    """
  end

  #
  # Misc Helpers
  #

  @spec id_ref(binary()) :: binary()
  defp id_ref(id), do: "#" <> id
end
