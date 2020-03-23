defmodule SmlrTest do
  use ExUnit.Case
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
      |> put_req_header("accept-encoding", " deflate;q=0.2 , gzip;q=1, br;q=0.5")
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
end
