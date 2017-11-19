defmodule EmqThrottlePluginTest do
  use ExUnit.Case, async: true
  doctest EmqThrottlePlugin
  require EmqThrottlePlugin.Shared

  @topic "such/example/chat"

  setup_all do
    :emqttd_access_control.start_link()
    {:ok, _emttd_throttle} = EmqThrottlePlugin.start(nil, nil)

    {:ok, []}
  end


  test "sending one message" do
    mqtt_client = EmqThrottlePlugin.Shared.mqtt_client(username: "not_user")
    assert EmqThrottlePlugin.Throttle.check_acl({mqtt_client, nil, @topic}, []) == :allow
  end
end
