defmodule EmqThrottlePlugin.Utils do
  def to_bool(nil), do: false
  def to_bool(v), do: String.to_existing_atom(v)

  def to_int(nil), do: 0
  def to_int(v), do: String.to_integer(v)

  def expire_time() do
    String.to_integer(System.get_env("REDIS_EXPIRE_TIME") || "60")
  end

  def count_limit() do
    String.to_integer(System.get_env("REDIS_COUNT_LIMIT") || "10")
  end

  def is_superuser?(username) do
    su = System.get_env("MQTT_ADMIN_USER_SUBSTRING") || "admin"
    String.contains?(username, su)
  end
end
