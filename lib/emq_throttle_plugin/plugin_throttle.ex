defmodule EmqThrottlePlugin.Throttle do
  require EmqThrottlePlugin.Shared
  alias EmqThrottlePlugin.{Redis, Utils}

  @behaviour :emqttd_acl_mod
  @redis_expire_time String.to_integer(System.get_env("REDIS_EXPIRE_TIME") || "60")
  @redis_count_limit String.to_integer(System.get_env("REDIS_COUNT_LIMIT") || "10")

  def init(params) do
    {:ok, params}
  end

  def check_acl({client, pubsub, topic} = _args, _state) do
    case pubsub do
      :publish -> throttle({client, topic})
      :subscribe -> :allow
      _ -> :allow
    end
  end

  def reload_acl(_state), do: :ok

  def description do
    "Throttling messages using redis as backend"
  end

  def build_key(username, topic) do 
    topic <> "-" <> username
  end

  def throttle({client, topic}, window \\ @redis_expire_time) do
    username = EmqThrottlePlugin.Shared.mqtt_client(client, :username)
    key = build_key(username, topic)

    if incr(key, window) do
      check_throttle(key, window)
    else
      :allow
    end
  end

  defp check_throttle(key, window) do
    result = values(key)
    if result do
      {count, in_backoff, backoff, time} = result
      if in_backoff do
        if is_in_backoff?(backoff, time) do
          :deny
        else
          end_backoff(key)
          :allow
        end
      else
        if count <= @redis_count_limit do 
          :allow
        else 
          expire_time = if backoff == 0, do: 2*window, else: 2*backoff+window
          set_backoff(key, backoff, window)
          expire(key, expire_time)
          :deny
        end
      end
    else
      :allow
    end
  end

  defp expire(key, window) do
    Redis.command(["EXPIRE", key, window])
  end

  defp incr(key, window) do
    count = Redis.command(["HINCRBY", key, "count", 1])
    if count && count == 1, do: expire(key, window)
    count
  end

  defp values(key) do
    result = Redis.command(["HMGET", key, "count", "in_backoff", "backoff", "time"])
    if result != nil do
      [count, in_backoff, backoff, time] = result
      {Utils.to_int(count), 
        Utils.to_bool(in_backoff),
        Utils.to_int(backoff),
        Utils.to_int(time)}
    else
      nil
    end
  end

  defp set_backoff(key, backoff, window \\ @redis_expire_time) do
    backoff = if backoff > 0, do: 2*backoff, else: window
    now = :os.system_time(:seconds)
    Redis.command([
      "HMSET", key, 
      "in_backoff", true, 
      "backoff", backoff,
      "time", now,
    ])
  end

  defp is_in_backoff?(backoff, time) do
    now = :os.system_time(:seconds)
    now < time + backoff
  end

  defp end_backoff(key) do
    Redis.command([
      "HMSET", key, 
      "in_backoff", false, 
      "count", 1,
    ])
  end
end
