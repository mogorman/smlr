defmodule Smlr.Compressor.BrotliTest do
  use ExUnit.Case
  alias Smlr.Compressor.Brotli

  test "can compress a file" do
    blob = Brotli.compress("hello world", [])
    brotli_hello_world = <<11, 5, 128, 104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 3>>
    assert(brotli_hello_world == blob)
  end
end
