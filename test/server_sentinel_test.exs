defmodule ServerSentinelTest do
  use ExUnit.Case
  doctest ServerSentinel

  test "greets the world" do
    assert ServerSentinel.hello() == :world
  end
end
