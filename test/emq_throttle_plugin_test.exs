defmodule EmqThrottlePluginTest do
  use ExUnit.Case
  doctest EmqThrottlePlugin

  test "greets the world" do
    assert EmqThrottlePlugin.hello() == :world
  end
end
