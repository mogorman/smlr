defmodule Smlr.Compressor do
  @moduledoc false &&
               """
               A behaviour describing a generic compressor backend.
               """

  @callback compress(String.t(), Keyword.t()) :: binary()
  @callback name() :: String.t()
  @callback level(Keyword.t()) :: integer()
  @callback default_level() :: integer()
end
