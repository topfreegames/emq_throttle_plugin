defmodule EmqThrottlePlugin.Redis do
  @redis_instances String.to_integer(System.get_env("REDIS_AUTH_REDIS_POOL_SIZE") || "5")

  def command(command) do
    Redix.command(:"redix_#{random_index()}", command)
  end

  def pipeline(pipeline) do
    Redix.pipeline(:"redix_#{random_index()}", pipeline)
  end

  defp random_index do
    rem(System.unique_integer([:positive]), @redis_instances)
  end
end
