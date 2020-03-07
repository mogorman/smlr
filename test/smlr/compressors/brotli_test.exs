defmodule Smlr.Compressor.BrotliTest do
  use ExUnit.Case

  test "can compress a file" do
    blob = Smlr.Compressor.Brotli.compress("hello world", [])
    assert("hello world" == :brotli.decode(blob))
  end
end
