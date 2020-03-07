defmodule Smlr.Compressor.Deflate do
  @moduledoc false

  @behaviour Smlr.Compressor

  alias Smlr.Config

  def name do
    "deflate"
  end

  def default_level do
    4
  end

  def level(opts) do
    Config.get_compressor_level(__MODULE__, opts)
  end

  def compress(data, opts) do
    z = :zlib.open()
    :zlib.deflateInit(z, level(opts))
    bs = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :zlib.close(z)
    :erlang.list_to_binary(bs)
  end
end
