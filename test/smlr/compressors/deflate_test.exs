defmodule Smlr.Compressor.DeflateTest do
  use ExUnit.Case
  alias Smlr.Compressor.Deflate

  test "can compress a file" do
    blob = Deflate.compress("hello world", [])
    assert("hello world" == :zlib.uncompress(blob))
  end
end
