defmodule Smlr.Cache do
  @moduledoc """
  Documentation for Smlr.
  """

  def get_from_cache(body, type, level, %{cache_opts: %{enabled: true}}) do
    case Cachex.get(Smlr.DefaultCache, "#{type}#{level}#{body}") do
      {:error, :no_cache} ->
        :telemetry.execute([:smlr, :request, :cache, :not_started], %{}, %{})

      {:error, _} ->
        :telemetry.execute([:smlr, :request, :cache, :miss], %{}, %{})
        nil

      {:ok, compressed} ->
        :telemetry.execute([:smlr, :request, :cache, :hit], %{}, %{})
        compressed
    end
  end

  def get_from_cache(_body, _type, _opts) do
    nil
  end

  def set_for_cache(compressed, type, body, level, %{cache: %{enabled: true, timeout: timeout, name: name}}) do
    case timeout do
      :infinity -> Cachex.put(name, "#{type}#{level}#{body}", compressed)
      _ -> Cachex.put(name, "#{type}#{level}#{body}", compressed, ttl: :timer.seconds(timeout))
    end

    :telemetry.execute([:smlr, :request, :cache, :set], %{}, %{timeout: timeout})
    compressed
  end

  def set_for_cache(compressed, _type, _body, _opts) do
    compressed
  end
end
