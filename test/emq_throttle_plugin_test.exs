defmodule EmqThrottlePluginTest do
  use ExUnit.Case, async: true
  doctest EmqThrottlePlugin
  require EmqThrottlePlugin.Shared
  alias EmqThrottlePlugin.{Redis, Throttle}

  @testtopic "test"
  @topic "chat/name/example"
  @disabled_topic "chat/anothername/example"
  @user "such_user"
  @admin "root_user"

  setup_all do
    System.put_env("REDIS_EXPIRE_TIME", "3")
    System.put_env("MQTT_THROTTLE_NAME_ENABLED", "true")
    System.put_env("MQTT_ADMIN_USER_SUBSTRING", "admin,root")

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

  test "sending one message in test topic" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @testtopic}, []) == :allow
  end

  test "sending 20 messages on disabled topic" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @testtopic}, []) == :allow
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

  test "when admin is sending many messages" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @admin)

    assert Enum.map(1..20, fn _ -> EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @topic}, []) end)
    |> Enum.all?(&(&1 == :allow))
  end

  test "when sending many messages to disabled topic" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)

    assert Enum.map(1..20, fn _ -> EmqThrottlePlugin.Throttle.check_acl({mqtt_client, :publish, @disabled_topic}, []) end)
    |> Enum.all?(&(&1 == :allow))
  end
end
