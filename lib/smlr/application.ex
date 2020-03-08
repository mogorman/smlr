defmodule Smlr.Application do
  @moduledoc false

  use Application
  alias Smlr.Config
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    with cache_opts <- Config.config(:cache_opts, []),
         {:ok, true} <- Map.fetch(cache_opts, :enable) do
      cachex =
        case Map.fetch(cache_opts, :limit) do
          {:ok, nil} ->
            worker(Cachex, [Smlr.DefaultCache, []])

          {:ok, limit} ->
            worker(Cachex, [Smlr.DefaultCache, [limit: limit, reclaim: 0.1]])

          _ ->
            worker(Cachex, [Smlr.DefaultCache, []])
        end

      children = [
        cachex
      ]

      opts = [strategy: :one_for_one, name: Smlr.Supervisor]
      Supervisor.start_link(children, opts)
    else
      _ ->
        :ok
    end
  end
end
