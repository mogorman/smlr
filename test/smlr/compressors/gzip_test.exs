defmodule Smlr.Compressor.GzipTest do
  use ExUnit.Case

  test "can compress a file" do
    blob = Smlr.Compressor.Gzip.compress("hello world", [])
    assert("hello world" == :zlib.gunzip(blob))
  end
end
