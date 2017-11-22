defmodule EmqThrottlePlugin.Throttle do
  require EmqThrottlePlugin.Shared
  require Logger
  alias EmqThrottlePlugin.{Redis, Utils}

  @behaviour :emqttd_acl_mod

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
    "throttle:" <> Utils.name_from_topic(topic) <> ":" <> topic <> "-" <> username
  end

  def throttle({client, topic}, window \\ Utils.expire_time()) do
    username = EmqThrottlePlugin.Shared.mqtt_client(client, :username)
    key = build_key(username, topic)

    if Utils.is_superuser?(username) or not Utils.is_enabled?(topic) do
      :allow
    else
      result = incr_and_get(key)
      if result do
        check_throttle(result, key, username, topic, window)
      else
        :allow
      end
    end
  end

  defp check_throttle(result, key, username, topic, window) do
    values = extract(result)
    {count, in_backoff, backoff, time} = values
    if in_backoff do
      if is_in_backoff?(backoff, time) do
        deny(username, topic)
      else
        end_backoff(key)
        :allow
      end
    else
      if count <= Utils.count_limit(topic) do 
        :allow
      else 
        expire_time = if backoff == 0, do: 2*window, else: 2*backoff+window
        set_backoff(key, backoff, expire_time, window)
        deny(username, topic)
      end
    end
  end

  defp incr_and_get(key) do
    result = Redis.pipeline([
      ["HINCRBY", key, "count", 1],
      ["HMGET", key, "count", "in_backoff", "backoff", "time"],
    ])
    if result, do: Enum.at(result, 1), else: nil
  end

  defp extract(result) do
    [count, in_backoff, backoff, time] = result
    {Utils.to_int(count), 
      Utils.to_bool(in_backoff),
      Utils.to_int(backoff),
      Utils.to_int(time)}
  end

  defp set_backoff(key, backoff, expire_time, window) do
    backoff = if backoff > 0, do: 2*backoff, else: window
    now = :os.system_time(:seconds)
    Redis.pipeline([
      ["HMSET", key, 
      "in_backoff", true, 
      "backoff", backoff,
       "time", now], 
      ["EXPIRE", key, expire_time],
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

  defp deny(username, topic) do
    Logger.info fn -> "user #{username} on topic #{topic} exceeded throttle limit" end
    :deny
  end
end
