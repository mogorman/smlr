defmodule Smlr.Compressor.ZstdTest do
  use ExUnit.Case

  test "can compress a file" do
    blob = Smlr.Compressor.Zstd.compress("hello world", [])
    assert("hello world" == :zstd.decompress(blob))
  end
end
