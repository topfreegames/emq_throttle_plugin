defmodule EmqThrottlePlugin.Throttle do
  @moduledoc """
  Throttle access redis to control how many messages
  was sent by user. If it exceeds, a backoff time is set
  and the user receives ACL deny during this period.
  When this period ends, the user can send messages again.
  If he/she doesn't blow throttle again, the key is removed
  from redis and the backoff time reseted.
  If he/she blows the throttle again, the backoff time 
  is set to 2 times the previous one.
  """

  require EmqThrottlePlugin.Shared
  require Logger
  alias EmqThrottlePlugin.{Redis, Utils}

  @behaviour :emqttd_acl_mod

  @doc """
  The implementation of init function from emqttd_acl_mod.
  """
  def init(params) do
    {:ok, params}
  end

  @doc """
  The implementation of check_acl function from emqttd_acl_mod.
  On subscribe, returns allow or ignore.
  On publish, checks if user exceeded throttle.
  """
  def check_acl({client, pubsub, topic} = _args, _state) do
    case pubsub do
      :publish -> throttle({client, topic}, Utils.expire_time(topic))
      :subscribe -> :ignore
      _ -> :ignore
    end
  end

  @doc """
  The implementation of reload_acl function from emqttd_acl_mod.
  """
  def reload_acl(_state), do: :ok

  @doc """
  The implementation of description function from emqttd_acl_mod.
  """
  def description do
    "Throttling messages using redis as backend"
  end

  @doc """
  Returns the redis key using topic and username. Name is, by conventions,
  the second part of the topic which is separated by forward slash.
  """
  def build_key(username, topic) do 
    "throttle:" <> Utils.name_from_topic(topic) <> ":" <> topic <> "-" <> username
  end

  @doc """
  Returnst :allow if user is superuser or if this name, extracted from topic, is 
  disabled (which is the default).
  Otherwise, increments user number of messages and checks if he/she exceeded throttle.
  """
  def throttle({client, topic}, window) do
    username = EmqThrottlePlugin.Shared.mqtt_client(client, :username)
    key = build_key(username, topic)

    if Utils.is_superuser?(username) or not Utils.is_enabled?(topic) do
      :allow
    else
      result = incr_and_get(key, window)
      if result do
        check_throttle(result, key, username, topic, window)
      else
        :ignore
      end
    end
  end

  defp check_throttle(result, key, username, topic, window) do
    values = extract(result)
    {count, in_backoff, backoff, time} = values

    if count == 1 do
      expire(key, window)
    end

    if in_backoff do
      if is_in_backoff?(backoff, time) do
        deny(username, topic)
      else
        end_backoff(key)
        :ignore
      end
    else
      if count <= Utils.count_limit(topic) do 
        :ignore
      else 
        expire_time = if backoff == 0, do: 2*window, else: 2*backoff+window
        set_backoff(key, backoff, expire_time, window)
        deny(username, topic)
      end
    end
  end

  defp incr_and_get(key, window) do
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

  defp expire(key, window) do
    Redis.command(["EXPIRE", key, window])
  end
end
