defmodule EmqThrottlePlugin.Throttle do
  require EmqThrottlePlugin.Shared

  @behaviour :emqttd_acl_mod

  def init(params) do
    {:ok, params}
  end

  def check_acl({client, _pubsub, topic} = _args, _state) do
    throttle({client, topic})
  end

  def reload_acl(_state), do: :ok

  def description do
    "Throttling messages using redis as backend"
  end

  defp throttle({client, topic}) do
    :allow
  end

  defp build_key(username, topic) do 
    topic <> "-" <> username
  end
end
