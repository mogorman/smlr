defmodule SmlrTest.PetsController do
  use Phoenix.Controller

  def index(conn, _params) do
    json(conn, %{"pet" => "asdf"})
  end

  def index_nil(conn, _params) do
    conn
    |> Plug.Conn.send_file(200, "README.md")
  end
end
