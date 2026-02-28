defmodule LifeWebWeb.PageController do
  use LifeWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
