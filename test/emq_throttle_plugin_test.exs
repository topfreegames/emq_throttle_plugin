defmodule EmqThrottlePluginTest do
  use ExUnit.Case, async: true
  doctest EmqThrottlePlugin
  require EmqThrottlePlugin.Shared
  alias EmqThrottlePlugin.{Redis, Throttle}

  @topic "such/example/chat"
  @user "such_user"

  setup_all do
    System.put_env("REDIS_EXPIRE_TIME", "3")

    :emqttd_access_control.start_link()
    {:ok, _emttd_throttle} = EmqThrottlePlugin.start(nil, nil)

    {:ok, []}
  end

  setup do
    Redis.command(["del", Throttle.build_key(@user, @topic)])
    :ok
  end

  test "subscribing to a topic 20 times" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)

    assert Enum.map(1..20, fn _ -> EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :subscribe, @topic}, []) end)
    |> Enum.all?(&(&1 == :allow))
  end

  test "sending one message" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @topic}, []) == :allow
  end

  test "sending 11th message in less then 60s" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)

    assert Enum.map(1..10, fn _ -> EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @topic}, []) end)
    |> Enum.all?(&(&1 == :allow))
    
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @topic}, []) == :deny
  end

  test "if expires after window time" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    window = 1

    assert Enum.map(1..10, fn _ -> EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) end)
    |> Enum.all?(&(&1 == :allow))
    assert EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) == :deny
    :timer.sleep(1000)

    assert EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) == :allow
  end

  test "when number of messages exceeds twice" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    window = 1

    # first blow, backoff of 1s
    assert Enum.map(1..10, fn _ -> EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) end)
    |> Enum.all?(&(&1 == :allow))
    assert EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) == :deny
    :timer.sleep(1000)

    # second blow, backoff of 2s
    assert Enum.map(1..10, fn _ -> EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) end)
    |> Enum.all?(&(&1 == :allow))
    assert EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) == :deny
    :timer.sleep(1000)

    assert EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) == :deny
    :timer.sleep(1000)

    # allow again after 2s
    assert EmqThrottlePlugin.Throttle.throttle({mqtt_client, @topic}, window) == :allow
  end
end
