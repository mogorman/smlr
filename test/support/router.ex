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

  scope "/smlr", SmlrTest do
    pipe_through(:api)
    get("/pets", PetsController, :index)
  end

  scope "/smlr_disabled", SmlrTest do
    pipe_through(:api_disabled)
    get("/pets", PetsController, :index)
  end
end
