defmodule Smlr.Compressor.ZstdTest do
  use ExUnit.Case

  alias Smlr.Compressor.Zstd

  test "can compress a file" do
    blob = Zstd.compress("hello world", [])
    assert("hello world" == :zstd.decompress(blob))
  end
end
