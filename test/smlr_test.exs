defmodule SmlrTest do
  use ExUnit.Case
  doctest Smlr

  test "greets the world" do
    assert Smlr.hello() == :world
  end
end
