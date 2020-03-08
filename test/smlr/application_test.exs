defmodule Smlr.ApplicationTest do
  use ExUnit.Case, async: true

  test "test application" do
    # one test because the sequence of these tests matters also testing cache in here for same reason
    compressed = <<1, 2, 3, 4>>

    # by default doesnt start
    assert(Smlr.Application.start(nil, nil) == :ok)

    result =
      Smlr.Cache.set(compressed, "body", "br", 4, %{cache: %{enable: false, timeout: :infinity, name: :smlr_test}})

    assert(result == <<1, 2, 3, 4>>)

    result = Smlr.Cache.get("body", "br", 4, %{cache_opts: %{enable: true}})
    assert(is_nil(result))

    # test if enabled without a limit
    Application.put_env(:smlr, :cache_opts, %{enable: true, timeout: :infinity, name: :smlr})
    {:ok, pid} = Smlr.Application.start(nil, nil)
    Supervisor.stop(pid)
    assert(is_pid(pid))

    # test limit if its set to nil
    Application.put_env(:smlr, :cache_opts, %{enable: true, timeout: :infinity, name: :smlr, limit: nil})
    {:ok, pid} = Smlr.Application.start(nil, nil)
    Supervisor.stop(pid)
    assert(is_pid(pid))

    # test if enabled and limit set
    Application.put_env(:smlr, :cache_opts, %{enable: true, timeout: :infinity, limit: 1, name: :smlr})
    {:ok, pid} = Smlr.Application.start(nil, nil)
    assert(is_pid(pid))

    Smlr.Cache.set(compressed, "body", "br", 4, %{cache: %{enable: true, timeout: :infinity, name: :smlr_test}})
    result = Smlr.Cache.get("body", "br", 4, %{cache_opts: %{enable: true}})
    assert(result == <<1, 2, 3, 4>>)

    result = Smlr.Cache.get("bodys", "br", 4, %{cache_opts: %{enable: true}})
    assert(is_nil(result))

    Smlr.Cache.set(compressed, "body", "br", 4, %{cache: %{enable: true, timeout: 1, name: :smlr_test}})
    :timer.sleep(1010)
    result = Smlr.Cache.get("body", "br", 4, %{cache_opts: %{enable: true}})
    assert(is_nil(result))

    Cachex.put(Smlr.DefaultCache, "qfdsa", <<4, 4, 4, 4>>)
    Cachex.put(Smlr.DefaultCache, "qblah", <<4, 4, 4, 5>>)
    :timer.sleep(50)
    assert(Cachex.get(Smlr.DefaultCache, "qasdf") == {:ok, nil})
    Supervisor.stop(pid)
  end
end
