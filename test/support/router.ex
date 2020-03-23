defmodule SmlrTest.Router do
  use Phoenix.Router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Smlr)
  end

  pipeline :api_disabled do
    plug(:accepts, ["json"])
    plug(Smlr, enable: false)
  end

  pipeline :api_ignore_weight do
    plug(:accepts, ["json"])

    plug(Smlr,
      ignore_client_weight: true,
      compressors: [Smlr.Compressor.Gzip, Smlr.Compressor.Deflate, Smlr.Compressor.Brotli, Smlr.Compressor.Zstd]
    )
  end

  pipeline :api_cache do
    plug(:accepts, ["json"])

    plug(Smlr,
      ignore_client_weight: true,
      cache_opts: %{
        enable: true,
        timeout: :infinity,
        limit: nil
      }
    )
  end

  scope "/smlr", SmlrTest do
    pipe_through(:api)
    get("/pets", PetsController, :index)
  end

  scope "/smlr_disabled", SmlrTest do
    pipe_through(:api_disabled)
    get("/pets", PetsController, :index)
  end

  scope "/smlr_ignore_weight", SmlrTest do
    pipe_through(:api_ignore_weight)
    get("/pets", PetsController, :index)
  end

  scope "/smlr_cache", SmlrTest do
    pipe_through(:api_cache)
    get("/pets", PetsController, :index)
  end
end
