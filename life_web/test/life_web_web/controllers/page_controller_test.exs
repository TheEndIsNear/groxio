defmodule LifeWebWeb.PageControllerTest do
  use LifeWebWeb.ConnCase

  test "GET / redirects to LiveView", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Game of Life"
  end
end
