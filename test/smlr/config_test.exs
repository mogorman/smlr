defmodule Smlr.ConfigTest do
  use ExUnit.Case

  test "test options" do
    assert(Smlr.Config.config(:ignore_client_weight, ignore_client_weight: true) == true)
  end

  test "test compressor levels" do
    assert(Smlr.Config.get_compressor_level(Smlr.Compressor.Gzip, compressor_opts: [{Smlr.Compressor.Gzip, 1}]) == 1)
  end
end
