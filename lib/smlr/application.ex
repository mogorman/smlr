defmodule Smlr.Application do
  @moduledoc false

  use Application
  alias Smlr.Config

  def start(_type, _args) do
    with cache_opts <- Config.config(:cache_opts, []),
         {:ok, true} <- Map.get(cache_opts, :enabled) do
      name = Map.get(cache_opts, :name) || Smlr.DefaultCache

      cachex =
        case Map.fetch(cache_opts, :limit) do
          {:ok, limit} ->
            {Cachex, name, [limit: limit]}

          _ ->
            {Cachex, name}
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
