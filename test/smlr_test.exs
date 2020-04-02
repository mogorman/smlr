defmodule SmlrTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Smlr

  test "stupid init test to satisfy coveralls" do
    opts = [ignore_client_weight: true]
    assert(Smlr.init(opts) == opts)
  end

  test "test a conn compresses" do
    conn =
      conn(:get, "/smlr/pets")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", "gzip")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(:zlib.gunzip(conn.resp_body)) == %{"pet" => "asdf"})
    assert(Plug.Conn.get_resp_header(conn, "content-encoding") == ["gzip"])
    assert conn.status == 200
  end

  test "test a conn does not compress if not resuested" do
    conn =
      conn(:get, "/smlr/pets")
      |> put_req_header("content-type", "application/json")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(conn.resp_body) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test a conn compresses in order presented" do
    conn =
      conn(:get, "/smlr/pets")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", "deflate, gzip, br")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(:zlib.uncompress(conn.resp_body)) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test a conn compresses in order weighted" do
    conn =
      conn(:get, "/smlr/pets")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", " deflate;q=0.2 , gzip;q=1, br;q=0.5, invalid;q")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(:zlib.gunzip(conn.resp_body)) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test disabled does nothing" do
    conn =
      conn(:get, "/smlr_disabled/pets")
      |> put_req_header("content-type", "application/json")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(conn.resp_body) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test ignore weight ignores client weights" do
    conn =
      conn(:get, "/smlr_ignore_weight/pets")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", " deflate;q=1.0 , gzip;q=0.2, br;q=0.9")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(:zlib.gunzip(conn.resp_body)) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test uses content type filtering" do
    conn =
      conn(:get, "/smlr_types/pets")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", "gzip")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(:zlib.gunzip(conn.resp_body)) == %{"pet" => "asdf"})
    assert conn.status == 200

    conn =
      conn(:get, "/smlr_types/pets_zip")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", " deflate;q=1.0 , gzip;q=0.2, br;q=0.9")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(conn.resp_body) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test serves from cache" do
    Application.put_env(:smlr, :cache_opts, %{enable: true, timeout: :infinity})
    {:ok, pid} = Smlr.Application.start(nil, nil)

    conn =
      conn(:get, "/smlr_cache/pets")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", "gzip")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(:zlib.gunzip(conn.resp_body)) == %{"pet" => "asdf"})

    conn(:get, "/smlr_cache/pets")
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept-encoding", "gzip")
    |> SmlrTest.Router.call([])

    Supervisor.stop(pid)

    assert(Poison.decode!(:zlib.gunzip(conn.resp_body)) == %{"pet" => "asdf"})
    assert conn.status == 200
  end

  test "test nil data does not get header" do
    conn =
      conn(:get, "/smlr_types/pets_nil")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", " deflate;q=1.0 , gzip;q=0.2, br;q=0.9")
      |> SmlrTest.Router.call([])

    conn.resp_body
    assert(Plug.Conn.get_resp_header(conn, "content-encoding") == [])
    assert conn.status == 200
  end

  test "test handles empty application" do
    conn =
      conn(:get, "/smlr_types/pets_none")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept-encoding", " deflate;q=1.0 , gzip;q=0.2, br;q=0.9")
      |> SmlrTest.Router.call([])

    assert(Poison.decode!(conn.resp_body) == %{"pet" => "asdf"})
    assert conn.status == 200
  end
end
