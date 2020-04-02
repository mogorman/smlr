defmodule SmlrTest.PetsController do
  use Phoenix.Controller

  def index(conn, _params) do
    json(conn, %{"pet" => "asdf"})
  end

  def index_nil(conn, _params) do
    conn
    |> Plug.Conn.send_file(200, "README.md")
  end

  def index_zip(conn, _params) do
    conn
    |> Plug.Conn.put_resp_content_type("application/zip")
    |> Plug.Conn.send_resp(200, "{\"pet\": \"asdf\"}")
  end
end
