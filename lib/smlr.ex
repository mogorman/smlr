defmodule Smlr do
  @moduledoc """
  Documentation for Smlr.
  """

  def try_start_cache(%{enabled: false}) do
    nil
  end

  def try_start_cache(%{enabled: true, max_cache_responses: limit, name: name}) do
    case Cachex.start(name, limit: limit) do
      {:ok, _} -> nil
      # this is because in dev mode plug init is called on every connection and it would be annoying for most users
      {:error, :not_started} -> nil
      {:error, {:already_started, _}} -> nil
    end
  end

  defp valid_compressor?("gzip") do
    true
  end

  defp valid_compressor?("deflate") do
    true
  end

  defp valid_compressor?("br") do
    true
  end

  defp valid_compressor?("zstd") do
    true
  end

  defp valid_compressor?(_) do
    false
  end

  def supported_compressors(compressors) do
    Enum.reduce(compressors, [], fn compressor, acc ->
      compressor = String.downcase(compressor) |> String.trim()

      case valid_compressor?(compressor) do
        true ->
          acc ++ [compressor]

        false ->
          acc
      end
    end)
  end

  def get_from_cache(_body, _type, %{cache: %{enabled: false}}) do
    nil
  end

  def get_from_cache(body, type, %{cache: %{enabled: true, name: name}} = opts) do
    case Cachex.get(name, "#{type}#{body}") do
      {:error, :no_cache} -> try_start_cache(opts.cache)
      {:error, _} -> nil
      {:ok, compressed} -> compressed
    end
  end

  def set_for_cache(compressed, _type, _body, %{cache: %{enabled: false}}) do
    compressed
  end

  def set_for_cache(compressed, type, body, %{
        cache: %{enabled: true, timeout: timeout, name: name}
      }) do
    case timeout do
      :infinity ->
        Cachex.put(name, "#{type}#{body}", compressed)

      _ ->
        Cachex.put(name, "#{type}#{body}", compressed, ttl: :timer.seconds(timeout))
    end

    compressed
  end

  def run_compress(body, "gzip") do
    :zlib.gzip(body)
  end

  def run_compress(body, "deflate") do
    :zlib.compress(body)
  end

  def run_compress(body, "br") do
    :brotli.encode(body)
  end

  def run_compress(body, "zstd") do
    :zstd.compress(body)
  end
end
