defmodule Smlr.Cache do
  @moduledoc """
  Documentation for Smlr.
  """

  @spec get(binary(), String.t(), integer(), map()) :: nil | binary()
  def get(body, type, level, %{cache_opts: %{enabled: true}}) do
    case Cachex.get(Smlr.DefaultCache, "#{type}#{level}#{body}") do
      {:error, :no_cache} ->
        :telemetry.execute([:smlr, :request, :cache, :not_started], %{}, %{})
        nil

      {:error, _} ->
        :telemetry.execute([:smlr, :request, :cache, :miss], %{}, %{})
        nil

      {:ok, compressed} ->
        :telemetry.execute([:smlr, :request, :cache, :hit], %{}, %{})
        compressed
    end
  end

  def get(_body, _type, _level, _opts) do
    nil
  end

  @spec set(binary(), String.t(), binary(), integer(), map()) :: binary()
  def set(compressed, body, type, level, %{cache: %{enabled: true, timeout: timeout, name: name}}) do
    case timeout do
      :infinity -> Cachex.put(name, "#{type}#{level}#{body}", compressed)
      _ -> Cachex.put(name, "#{type}#{level}#{body}", compressed, ttl: :timer.seconds(timeout))
    end

    :telemetry.execute([:smlr, :request, :cache, :set], %{}, %{timeout: timeout})
    compressed
  end

  def set(compressed, _body, _type, _level, _opts) do
    compressed
  end
end
