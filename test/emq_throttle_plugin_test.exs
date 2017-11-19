defmodule EmqThrottlePluginTest do
  use ExUnit.Case, async: true
  doctest EmqThrottlePlugin
  require EmqThrottlePlugin.Shared
  alias EmqThrottlePlugin.{Redis, Throttle}

  @topic "such/example/chat"
  @user "such_user"

  setup_all do
    :emqttd_access_control.start_link()
    {:ok, _emttd_throttle} = EmqThrottlePlugin.start(nil, nil)

    {:ok, []}
  end

  setup do
    Redis.command(["del", Throttle.build_key(@user, @topic)])
    :ok
  end

  test "sending one message" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, nil, @topic}, []) == {:ok, :allow}
  end

  test "should deny after 10 requests" do
    Redis.command(["set", Throttle.build_key(@user, @topic), 9])
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: @user)
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, nil, @topic}, []) == {:ok, :deny}
  end
end
