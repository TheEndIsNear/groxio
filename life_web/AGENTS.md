# AGENTS.md — Life Web (Conway's Game of Life)

Phoenix 1.8 / LiveView 1.1 web application. No database. Pure in-memory game state via GenServer + PubSub. Canvas rendering via JS hooks.

## Build, test, and lint commands

```bash
mix setup                  # Install deps + build assets
mix compile                # Compile only
mix format                 # Auto-format all .ex/.exs/.heex files
mix test                   # Run all tests
mix test test/path.exs     # Run a single test file
mix test test/path.exs:42  # Run a single test at line 42
mix test --failed          # Re-run previously failed tests
mix credo --strict         # Static analysis (style + consistency)
mix dialyzer               # Type checking (first run builds PLT — slow)
mix precommit              # Compile (warnings-as-errors) + unlock unused deps + format + test + credo --strict + dialyzer
```

Always run `mix precommit` when finished with all changes and fix any issues before considering work complete.

## Project structure

```
lib/
  life_web/                          # Domain layer (LifeWeb.*)
    application.ex                   # OTP supervision tree
    game_of_life.ex                  # Pure-functional game logic
    game_of_life/server.ex           # GenServer per-client game state
  life_web_web/                      # Web layer (LifeWebWeb.*)
    router.ex                        # Routes (root scope aliased to LifeWebWeb)
    live/game_live.ex                # Main LiveView
    components/
      core_components.ex             # Phoenix-generated UI components
      game_components.ex             # Game-specific function components
      layouts.ex                     # App layout, flash_group, theme toggle
assets/
  js/app.js                          # Single JS entrypoint; hooks registered here
  js/hooks/                          # External JS hooks (one file per hook)
  css/app.css                        # Tailwind v4 + daisyUI config
  vendor/                            # Vendored JS (no npm)
test/                                # Mirrors lib/ directory structure
```

## Module naming

- **Domain modules**: `LifeWeb.*` (e.g., `LifeWeb.GameOfLife`, `LifeWeb.GameOfLife.Server`)
- **Web modules**: `LifeWebWeb.*` (e.g., `LifeWebWeb.GameLive`, `LifeWebWeb.GameComponents`)
- **OTP app name**: `:life_web`
- LiveViews use the `Live` suffix: `LifeWebWeb.GameLive`
- One module per file — never nest module definitions

## Code style

### Ordering within modules

1. `use` / `@moduledoc`
2. `import` (with `only:` when selective)
3. `alias`
4. Module attributes / constants (`@default_rows`, `@pattern_categories`)
5. Public functions with `@doc` / `@spec`
6. Private functions (`defp`)

### Documentation and types

- `@moduledoc` on all modules (use `@moduledoc false` for internal modules like Application)
- `@doc` on every public function — short one-liners for simple functions, multi-line with `## Options` for complex ones
- `@spec` on all public functions in domain modules
- `@type` for domain-specific types (e.g., `@type cell :: {non_neg_integer(), non_neg_integer()}`)
- Function components use `attr` declarations with `:type`, `:required`, and `:doc`

### Naming

- Predicate functions end in `?` (e.g., `survives?/3`) — never prefix with `is_`
- Private helpers use descriptive names: `do_evolve`, `schedule_tick`, `cancel_timer`
- Section comments to organize long modules: `# --- Client API ---`, `# --- Callbacks ---`

### Error handling

- Use `{:ok, value}` / `:error` tuples for operations that can fail
- Pattern match on results with `case` — no `with` chains unless needed for 3+ fallible steps
- Avoid `else` on a `with` block, we do not want to hide errors and want the function calling to properly deal with the error passed back to it.
- GenServer callbacks always return proper `{:noreply, state}` / `{:reply, value, state}`
- Avoid `String.to_atom/1` on user input — use `String.to_existing_atom/1`

### Pipes and rebinding

- Pipe operator for data transformation chains, but only if there is more than one pipe, **never** do `socket |> assign()` **instead** do `assign(socket)`
- Socket assignment chains: `socket |> assign(:key, val) |> push_event(...)`
- Rebind `state` through sequential updates in GenServer handlers:
  ```elixir
  state = cancel_timer(state)
  state = %{state | grid: new_grid, generation: 0}
  ```

### Formatting

- `.formatter.exs` uses `Phoenix.LiveView.HTMLFormatter` plugin
- `mix format` runs automatically as part of `mix precommit`

### Best practices
- in every project include credo, and dialyzer to check for incorrect patterns and bad type errors
- **never** use `unless` **always** use `if`

## LiveView conventions

- Wrap all content in `<Layouts.app flash={@flash}>` (Layouts is aliased via `life_web_web.ex`)
- Use `@impl true` on all callbacks
- Callback order: `mount/3` → `render/1` → `handle_event/3` → `handle_info/2`
- Thin event handlers that delegate to the GenServer client API
- State updates flow back via PubSub, not direct socket mutation from GenServer calls
- Use `push_event/3` to send data to JS hooks; always rebind or return the socket

### Function components

- Extract UI sections into dedicated component modules (e.g., `LifeWebWeb.GameComponents`)
- Use `Phoenix.Component` with `attr` declarations — not private `defp` components in LiveViews
- Import selectively: `import LifeWebWeb.CoreComponents, only: [icon: 1]`
- Use `<.icon name="hero-x-mark" class="size-4" />` for icons — never use Heroicons modules directly

### Forms

- Create via `to_form(params, as: :name)` — never pass changesets directly to templates
- Always give forms a unique DOM ID: `<.form for={@form} id="settings-form">`
- Access fields via `@form[:field]`

### Templates (HEEx)

- Use `~H` sigil (inline) — this project does not use separate `.heex` files for LiveViews
- Use `{@value}` for attribute and body interpolation; `<%= ... %>` only for block constructs (if/for/cond)
- Conditional classes use list syntax: `class={["base", @flag && "extra"]}`
- Comments: `<%!-- comment --%>`
- Give key elements unique DOM IDs for testability (`id="btn-start"`, `id="game-canvas"`)

## JavaScript and CSS

- **Single entrypoint**: `assets/js/app.js` and `assets/css/app.css`
- External JS hooks go in `assets/js/hooks/` — register in `app.js` via `Hooks` object
- Colocated hooks use `:type={Phoenix.LiveView.ColocatedHook}` and must start with `.` prefix
- Never write raw `<script>` tags in HEEx templates
- All vendor deps live in `assets/vendor/` — no npm
- **Tailwind CSS v4** with `@import "tailwindcss" source(none)` syntax — no `tailwind.config.js`
- **daisyUI** component classes for UI (btn, card, range, badge, etc.)
- Never use `@apply` in CSS
- Theme system: light/dark/system via `data-theme` attribute on `<html>`

## Testing

- Tests mirror `lib/` structure under `test/`
- Unit tests: `use ExUnit.Case, async: true` for pure-functional modules
- LiveView tests: `use LifeWebWeb.ConnCase` + `import Phoenix.LiveViewTest`
- Always use `start_supervised!/1` to start processes in tests
- Use unique PubSub topics per test: `"test:game:#{System.unique_integer()}"`
- Drain initial broadcasts: `assert_receive {:game_update, _}, 500`
- Prefer `assert_receive` over `Process.sleep` for async assertions
- Use `:sys.get_state/1` to synchronize with GenServer state
- Assert on element presence via `has_element?(view, "#element-id")` — not raw HTML
- Debug selectors with `LazyHTML.filter(LazyHTML.from_fragment(render(view)), "selector")`

## Architecture (data flow)

```
LiveView mount → DynamicSupervisor.start_child(Server) → PubSub.subscribe(topic)
User interaction → handle_event → Server.api_call(pid) → GenServer updates state
GenServer → PubSub.broadcast({:game_update, snapshot}) → LiveView handle_info
LiveView → assign(:game, state) + push_event("game_update", data) → JS Hook redraws canvas
```

- Each browser tab gets its own GenServer under `LifeWeb.GameSupervisor`
- Topic format: `"game:#{socket.id}"`
- Server crashes are recovered via `Process.monitor/1` + `:DOWN` handler in the LiveView
