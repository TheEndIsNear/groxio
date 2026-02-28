defmodule LifeWebWeb.GameLive do
  @moduledoc """
  LiveView for Conway's Game of Life.

  Each connected client gets its own game server instance managed
  under `LifeWeb.GameSupervisor`. The grid is rendered on an HTML5
  Canvas via a JavaScript hook, and control forms allow configuring
  grid size and simulation speed.
  """

  use LifeWebWeb, :live_view

  alias LifeWeb.GameOfLife.Server

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

    socket =
      socket
      |> assign(:page_title, "Game of Life")
      |> assign(:server, pid)
      |> assign(:topic, topic)
      |> assign(:game, game_state)
      |> assign(:form, to_form(form_params, as: :settings))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col items-center gap-8 w-full max-w-5xl mx-auto">
        <div class="text-center space-y-2">
          <h1 class="text-3xl font-bold tracking-tight">Conway's Game of Life</h1>
          <p class="text-sm text-base-content/60">
            Generation {@game.generation} · {@game.alive_count} cells alive
          </p>
        </div>

        <div class="flex flex-col lg:flex-row gap-6 w-full items-start justify-center">
          <%!-- Control Panel --%>
          <div class="w-full lg:w-72 space-y-4">
            <%!-- Playback Controls --%>
            <div class="card bg-base-200 p-4 space-y-3">
              <h2 class="font-semibold text-sm uppercase tracking-wide text-base-content/70">
                Controls
              </h2>
              <div class="flex flex-wrap gap-2">
                <%= if @game.running do %>
                  <button
                    id="btn-stop"
                    phx-click="stop"
                    class="btn btn-sm btn-warning flex-1"
                  >
                    <.icon name="hero-pause-solid" class="size-4" /> Pause
                  </button>
                <% else %>
                  <button
                    id="btn-start"
                    phx-click="start"
                    class="btn btn-sm btn-success flex-1"
                  >
                    <.icon name="hero-play-solid" class="size-4" /> Play
                  </button>
                  <button
                    id="btn-step"
                    phx-click="step"
                    class="btn btn-sm btn-ghost flex-1"
                  >
                    <.icon name="hero-forward-solid" class="size-4" /> Step
                  </button>
                <% end %>
              </div>
              <div class="flex flex-wrap gap-2">
                <button
                  id="btn-randomize"
                  phx-click="randomize"
                  class="btn btn-sm btn-secondary flex-1"
                >
                  <.icon name="hero-sparkles-solid" class="size-4" /> Random
                </button>
                <button
                  id="btn-clear"
                  phx-click="clear"
                  class="btn btn-sm btn-ghost flex-1"
                >
                  <.icon name="hero-trash-solid" class="size-4" /> Clear
                </button>
              </div>
            </div>

            <%!-- Settings Form --%>
            <div class="card bg-base-200 p-4 space-y-3">
              <h2 class="font-semibold text-sm uppercase tracking-wide text-base-content/70">
                Settings
              </h2>
              <.form for={@form} id="settings-form" phx-change="update_settings" class="space-y-3">
                <div>
                  <label class="label text-xs font-medium" for="settings-rows">
                    Rows: {@form[:rows].value}
                  </label>
                  <input
                    type="range"
                    id="settings-rows"
                    name="settings[rows]"
                    min="5"
                    max="100"
                    value={@form[:rows].value}
                    class="range range-sm range-primary w-full"
                  />
                </div>
                <div>
                  <label class="label text-xs font-medium" for="settings-cols">
                    Columns: {@form[:cols].value}
                  </label>
                  <input
                    type="range"
                    id="settings-cols"
                    name="settings[cols]"
                    min="5"
                    max="100"
                    value={@form[:cols].value}
                    class="range range-sm range-primary w-full"
                  />
                </div>
                <div>
                  <label class="label text-xs font-medium" for="settings-tick-ms">
                    Speed: {@form[:tick_ms].value}ms
                  </label>
                  <input
                    type="range"
                    id="settings-tick-ms"
                    name="settings[tick_ms]"
                    min="50"
                    max="2000"
                    step="50"
                    value={@form[:tick_ms].value}
                    class="range range-sm range-accent w-full"
                  />
                </div>
              </.form>
            </div>

            <%!-- Info --%>
            <div class="card bg-base-200 p-4 space-y-2 text-xs text-base-content/60">
              <p>Click on the canvas to toggle cells.</p>
              <p>Edges wrap around (toroidal grid).</p>
            </div>
          </div>

          <%!-- Canvas --%>
          <div class="flex-1 flex justify-center">
            <canvas
              id="game-canvas"
              phx-hook="GameOfLife"
              phx-update="ignore"
              data-rows={@game.rows}
              data-cols={@game.cols}
              class="border-2 border-base-300 rounded-lg cursor-crosshair bg-base-100"
              style="max-width: 100%; aspect-ratio: 1 / 1;"
            >
            </canvas>
          </div>
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
