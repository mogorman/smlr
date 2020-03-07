defmodule Smlr.Compressor.Zstd do
  @moduledoc false

  @behaviour Smlr.Compressor

  alias Smlr.Config

  def name() do
    "zstd"
  end

  def level(opts) do
    Config.get_compressor_level(__MODULE__, opts)
  end

  def default_level() do
    4
  end

  def compress(data, opts) do
    :zstd.compress(data, level(opts))
  end
end
