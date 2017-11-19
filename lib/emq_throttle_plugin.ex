defmodule EmqThrottlePlugin do
  use Application

  def start(_type, _args) do
    {:ok, supervisor} = EmqThrottlePlugin.Supervisor.start_link()
    :emqttd_access_control.register_mod(:acl, EmqThrottlePlugin.Throttle, [])
    {:ok, supervisor}
  end

  def stop(_app) do
  end
end
