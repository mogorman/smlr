defmodule SmlrTest do
  use ExUnit.Case
  doctest Smlr

  def build_fake_conn(method, url, path_params) do
    %Plug.Conn{
      assigns: %{},
      body_params: %{},
      method: method,
      host: "localhost",
      params: %{},
      path_info: [],
      path_params: path_params,
      private: %{
        :phoenix_router => FakeRouter
      },
      query_params: %{},
      query_string: "",
      remote_ip: {127, 0, 0, 1},
      req_cookies: [],
      req_headers: [],
      request_path: url
    }
  end

  test "stupid init test to satisfy coveralls" do
    opts = [ignore_client_weight: true]
    assert(Smlr.init(opts) == opts)
  end

  test "test enable flag can disable plug" do
    conn = build_fake_conn("GET", "/pet/44", %{"petId" => "44"})
    assert(Smlr.call(conn, enable: false) == conn)
  end

  test "test when no compression allowed none is applied" do
    conn = build_fake_conn("GET", "/pet/44", %{"petId" => "44"})
    assert(Smlr.call(conn, []) == conn)
  end

  test "test compression function is updated" do
    conn = build_fake_conn("GET", "/pet/44", %{"petId" => "44"})
    conn = %Plug.Conn{conn | req_headers: [{"accept-encoding", "gzip"}]}
    callback_added = Smlr.call(conn, [])
    assert(conn.before_send == [])
    assert(Enum.count(callback_added.before_send) == 1)
  end

  test "test we actually compress" do
    conn = build_fake_conn("POST", "/pet/44", %{"petId" => "44"})
    conn = %Plug.Conn{conn | req_headers: [{"accept-encoding", "gzip"}], resp_body: "%{\"hello\" => \"world\"}"}
    compressed = Smlr.compress_response(conn, compressor: Smlr.Compressor.Gzip)
    assert(conn.resp_body == :zlib.gunzip(compressed.resp_body))
  end
end
