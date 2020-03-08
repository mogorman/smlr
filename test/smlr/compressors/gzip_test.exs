defmodule Smlr.Compressor.GzipTest do
  use ExUnit.Case

  alias Smlr.Compressor.Gzip

  test "can compress a file" do
    blob = Gzip.compress("hello world", [])
    assert("hello world" == :zlib.gunzip(blob))
  end
end
