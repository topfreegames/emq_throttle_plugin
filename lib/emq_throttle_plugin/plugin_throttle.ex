defmodule EmqThrottlePlugin.Throttle do
  require EmqThrottlePlugin.Shared
  alias EmqThrottlePlugin.Redis

  @behaviour :emqttd_acl_mod
  @redis_expire_time String.to_integer(System.get_env("REDIS_EXPIRE_TIME") || "60")
  @redis_count_limit String.to_integer(System.get_env("REDIS_COUNT_LIMIT") || "10")

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
    username = EmqThrottlePlugin.Shared.mqtt_client(client, :username)
    key = build_key(username, topic)
    case Redis.command(["incr", key]) do
      {:error, message} -> {:error, message}

      {:ok, count} ->
        if count == 1 do
          expire(key)
        end
        if count < @redis_count_limit do
          {:ok, :allow}
        else
          {:ok, :deny}
        end

      {_, result} -> IO.puts result
    end
  end

  def build_key(username, topic) do 
    topic <> "-" <> username
  end

  defp expire(key) do
    Redis.command(["expire", key, @redis_expire_time])
  end
end
