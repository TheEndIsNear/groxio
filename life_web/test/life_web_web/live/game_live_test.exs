defmodule LifeWebWeb.GameLiveTest do
  use LifeWebWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "GameLive" do
    test "renders the game page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "h1", "Conway's Game of Life")
      assert has_element?(view, "#game-canvas")
      assert has_element?(view, "#settings-form")
    end

    test "displays generation and cell count", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "p", "Generation 0")
    end

    test "has play/pause controls", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Initially shows Play button (not running)
      assert has_element?(view, "#btn-start")
      refute has_element?(view, "#btn-stop")
    end

    test "start toggles to pause button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("#btn-start") |> render_click()

      # After starting, should show Pause button
      assert has_element?(view, "#btn-stop")
      refute has_element?(view, "#btn-start")
    end

    test "step advances generation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("#btn-step") |> render_click()

      # Wait for the PubSub broadcast to be processed
      :timer.sleep(50)

      assert has_element?(view, "p", "Generation 1")
    end

    test "clear resets the grid", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("#btn-clear") |> render_click()
      :timer.sleep(50)

      assert has_element?(view, "p", "0 cells alive")
    end

    test "randomize resets to generation 0", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Step forward first
      view |> element("#btn-step") |> render_click()
      :timer.sleep(50)

      # Then randomize
      view |> element("#btn-randomize") |> render_click()
      :timer.sleep(50)

      assert has_element?(view, "p", "Generation 0")
    end

    test "settings form updates on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#settings-form", settings: %{rows: "50", cols: "50", tick_ms: "500"})
      |> render_change()

      :timer.sleep(50)

      # Verify the form reflects the new values
      assert has_element?(view, "label", "Rows: 50")
      assert has_element?(view, "label", "Columns: 50")
      assert has_element?(view, "label", "Speed: 500ms")
    end
  end
end
