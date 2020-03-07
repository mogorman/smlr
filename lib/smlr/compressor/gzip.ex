defmodule Smlr.Compressor.Gzip do
  @moduledoc false

  @behaviour Smlr.Compressor

  alias Smlr.Config

  def name() do
    "gzip"
  end

  def level(opts) do
    Config.get_compressor_level(__MODULE__, opts)
  end

  def default_level() do
    4
  end

  def compress(data, opts) do
    z = :zlib.open()
    :zlib.deflateInit(z, level(opts), :deflated, 31, 8, :default)
    bs = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :zlib.close(z)
    :erlang.iolist_to_binary(bs)
  end
end
