defmodule LifeWebWeb.GameLive do
  @moduledoc """
  LiveView for Conway's Game of Life.

  Each connected client gets its own game server instance managed
  under `LifeWeb.GameSupervisor`. The grid is rendered on an HTML5
  Canvas via a JavaScript hook, and control forms allow configuring
  grid size and simulation speed.
  """

  use LifeWebWeb, :live_view

  import LifeWebWeb.GameComponents

  alias LifeWeb.GameOfLife
  alias LifeWeb.GameOfLife.Server

  @pattern_categories [
    {:still_life, "Still Lifes"},
    {:oscillator, "Oscillators"},
    {:spaceship, "Spaceships"},
    {:generator, "Generators"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    rows = 30
    cols = 30
    tick_ms = 200

    topic = "game:#{socket.id}"

    {:ok, pid} =
      DynamicSupervisor.start_child(
        LifeWeb.GameSupervisor,
        {Server, topic: topic, rows: rows, cols: cols, tick_ms: tick_ms}
      )

    Process.monitor(pid)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(LifeWeb.PubSub, topic)
    end

    game_state = Server.get_state(pid)

    form_params = %{
      "rows" => to_string(rows),
      "cols" => to_string(cols),
      "tick_ms" => to_string(tick_ms)
    }

    patterns_by_category =
      for {cat_key, cat_label} <- @pattern_categories do
        items =
          GameOfLife.patterns()
          |> Enum.filter(fn p -> p.category == cat_key end)

        {cat_key, cat_label, items}
      end

    socket =
      socket
      |> assign(:page_title, "Game of Life")
      |> assign(:server, pid)
      |> assign(:topic, topic)
      |> assign(:game, game_state)
      |> assign(:form, to_form(form_params, as: :settings))
      |> assign(:pattern_categories, patterns_by_category)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col items-center gap-8 w-full max-w-5xl mx-auto">
        <.game_header game={@game} />

        <div class="flex flex-col lg:flex-row gap-6 w-full items-start justify-center">
          <div class="w-full lg:w-72 space-y-4">
            <.playback_controls running={@game.running} />
            <.settings_panel form={@form} />
            <.patterns_panel pattern_categories={@pattern_categories} />
            <.info_card />
          </div>

          <.game_canvas rows={@game.rows} cols={@game.cols} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  # --- Event handlers ---

  @impl true
  def handle_event("start", _params, socket) do
    Server.start(socket.assigns.server)
    {:noreply, socket}
  end

  def handle_event("stop", _params, socket) do
    Server.stop(socket.assigns.server)
    {:noreply, socket}
  end

  def handle_event("step", _params, socket) do
    Server.step(socket.assigns.server)
    {:noreply, socket}
  end

  def handle_event("randomize", _params, socket) do
    Server.randomize(socket.assigns.server)
    {:noreply, socket}
  end

  def handle_event("clear", _params, socket) do
    Server.clear(socket.assigns.server)
    {:noreply, socket}
  end

  def handle_event("load_pattern", %{"key" => key}, socket) do
    Server.load_pattern(socket.assigns.server, String.to_existing_atom(key))
    {:noreply, socket}
  end

  def handle_event("toggle_cell", %{"row" => row, "col" => col}, socket) do
    Server.toggle_cell(socket.assigns.server, row, col)
    {:noreply, socket}
  end

  def handle_event("update_settings", %{"settings" => params}, socket) do
    rows = String.to_integer(params["rows"])
    cols = String.to_integer(params["cols"])
    tick_ms = String.to_integer(params["tick_ms"])

    server = socket.assigns.server
    old_game = socket.assigns.game

    if rows != old_game.rows or cols != old_game.cols do
      Server.resize(server, rows, cols)
    end

    if tick_ms != old_game.tick_ms do
      Server.set_speed(server, tick_ms)
    end

    form_params = %{
      "rows" => to_string(rows),
      "cols" => to_string(cols),
      "tick_ms" => to_string(tick_ms)
    }

    {:noreply, assign(socket, :form, to_form(form_params, as: :settings))}
  end

  # --- PubSub handlers ---

  @impl true
  def handle_info({:game_update, game_state}, socket) do
    socket =
      socket
      |> assign(:game, game_state)
      |> push_event("game_update", %{
        rows: game_state.rows,
        cols: game_state.cols,
        alive_cells: game_state.alive_cells
      })

    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    if pid == socket.assigns.server do
      # Server crashed — restart it
      topic = socket.assigns.topic
      game = socket.assigns.game

      {:ok, new_pid} =
        DynamicSupervisor.start_child(
          LifeWeb.GameSupervisor,
          {Server, topic: topic, rows: game.rows, cols: game.cols, tick_ms: game.tick_ms}
        )

      Process.monitor(new_pid)
      {:noreply, assign(socket, :server, new_pid)}
    else
      {:noreply, socket}
    end
  end
end
