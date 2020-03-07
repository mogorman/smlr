defmodule Smlr.Compressor.DeflateTest do
  use ExUnit.Case

  test "can compress a file" do
    blob = Smlr.Compressor.Deflate.compress("hello world", [])
    assert("hello world" == :zlib.uncompress(blob))
  end
end
