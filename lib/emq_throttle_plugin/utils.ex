defmodule EmqThrottlePlugin.Utils do
  def to_bool(nil), do: false
  def to_bool(v), do: String.to_existing_atom(v)

  def to_int(nil), do: 0
  def to_int(v), do: String.to_integer(v)

  def expire_time() do
    String.to_integer(System.get_env("REDIS_EXPIRE_TIME") || "60")
  end

  def count_limit(topic) do
    name = name_from_topic(topic)
    envvar = "REDIS_" <> name <> "_COUNT_LIMIT"
    String.to_integer(System.get_env(envvar) || "10")
  end

  def name_from_topic(topic) do
    topic |> String.split("/") |> Enum.at(1) |> String.upcase
  end

  def is_superuser?(username) do
    su = System.get_env("MQTT_ADMIN_USER_SUBSTRING") || "admin"
    String.contains?(username, su)
  end
end
