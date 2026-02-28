defmodule LifeWebWeb.GameComponents do
  @moduledoc """
  Reusable function components for the Game of Life UI.

  These components render the game header, playback controls,
  settings panel, pattern selector, info card, and canvas.
  Import this module wherever the game UI is needed.
  """

  use Phoenix.Component

  import LifeWebWeb.CoreComponents, only: [icon: 1]

  @doc """
  Renders the game title and live generation/cell statistics.
  """
  attr :game, :map, required: true, doc: "game state snapshot with :generation and :alive_count"

  def game_header(assigns) do
    ~H"""
    <div class="text-center space-y-2">
      <h1 class="text-3xl font-bold tracking-tight">Conway's Game of Life</h1>
      <p class="text-sm text-base-content/60">
        Generation {@game.generation} · {@game.alive_count} cells alive
      </p>
    </div>
    """
  end

  @doc """
  Renders play/pause, step, random, and clear buttons.

  Shows a "Pause" button when the simulation is running,
  or "Play" and "Step" buttons when paused.
  """
  attr :running, :boolean, required: true, doc: "whether the simulation is currently running"

  def playback_controls(assigns) do
    ~H"""
    <div class="card bg-base-200 p-4 space-y-3">
      <h2 class="font-semibold text-sm uppercase tracking-wide text-base-content/70">
        Controls
      </h2>
      <div class="flex flex-wrap gap-2">
        <%= if @running do %>
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
    """
  end

  @doc """
  Renders the settings form with range sliders for rows, columns, and speed.
  """
  attr :form, Phoenix.HTML.Form, required: true, doc: "the settings form (as: :settings)"

  def settings_panel(assigns) do
    ~H"""
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
    """
  end

  @doc """
  Renders pattern preset buttons grouped by category.

  Each button fires a `"load_pattern"` event with a `key` value.
  """
  attr :pattern_categories, :list,
    required: true,
    doc: "list of {key, label, items} tuples grouped by category"

  def patterns_panel(assigns) do
    ~H"""
    <div class="card bg-base-200 p-4 space-y-3">
      <h2 class="font-semibold text-sm uppercase tracking-wide text-base-content/70">
        Patterns
      </h2>
      <div :for={{_key, label, items} <- @pattern_categories} class="space-y-1.5">
        <p class="text-xs font-medium text-base-content/50">{label}</p>
        <div class="flex flex-wrap gap-1.5">
          <button
            :for={pattern <- items}
            id={"btn-pattern-#{pattern.key}"}
            phx-click="load_pattern"
            phx-value-key={pattern.key}
            class="btn btn-xs btn-outline btn-primary"
          >
            {pattern.name}
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a small info card with usage hints.
  """
  def info_card(assigns) do
    ~H"""
    <div class="card bg-base-200 p-4 space-y-2 text-xs text-base-content/60">
      <p>Click on the canvas to toggle cells.</p>
      <p>Edges wrap around (toroidal grid).</p>
    </div>
    """
  end

  @doc """
  Renders the HTML5 Canvas element with the `GameOfLife` JS hook attached.

  The canvas uses `phx-update="ignore"` so LiveView does not touch
  the DOM managed by the JavaScript hook.
  """
  attr :rows, :integer, required: true, doc: "number of grid rows"
  attr :cols, :integer, required: true, doc: "number of grid columns"

  def game_canvas(assigns) do
    ~H"""
    <div class="flex-1 flex justify-center">
      <canvas
        id="game-canvas"
        phx-hook="GameOfLife"
        phx-update="ignore"
        data-rows={@rows}
        data-cols={@cols}
        class="border-2 border-base-300 rounded-lg cursor-crosshair bg-base-100"
        style="max-width: 100%; aspect-ratio: 1 / 1;"
      >
      </canvas>
    </div>
    """
  end
end
