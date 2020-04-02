defmodule Smlr.Config do
  @moduledoc false

  @defaults [
    enable: true,
    compressors: [
      Smlr.Compressor.Gzip,
      Smlr.Compressor.Deflate,
      Smlr.Compressor.Brotli,
      Smlr.Compressor.Zstd
    ],
    all_types: true,
    types: [
      "application/atom+xml",
      "application/javascript",
      "application/json",
      "application/xml",
      "application/xml+rss",
      "image/svg+xml",
      "text/css",
      "text/javascript",
      "text/plain",
      "text/xml"
    ],
    compressor_opts: [],
    cache_opts: %{
      enable: false,
      timeout: :infinity,
      limit: nil
    },
    ignore_client_weight: false
  ]

  defp default(key), do: @defaults[key]

  @doc ~S"""
  Returns the most specific non-nil config value it can, checking
  `opts`, `Application.get_env(:smlr, compressors)`,
  and `@defaults` (in that order).
  Returns `nil` if nothing was found.
  """
  @spec config(atom, Keyword.t()) :: any
  def config(key, opts \\ []) do
    cond do
      nil != (value = opts[key]) -> value
      nil != (value = Application.get_env(:smlr, key)) -> value
      :else -> default(key)
    end
  end

  def get_compressor_level(compressor, opts) do
    level =
      config(:compressor_opts, opts)
      |> Enum.find(fn {item, _level} -> item == compressor end)

    case level do
      nil ->
        compressor.default_level()

      {^compressor, level} ->
        level
    end
  end
end
