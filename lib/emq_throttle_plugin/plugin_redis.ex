defmodule EmqThrottlePlugin.Redis do
  @redis_instances String.to_integer(System.get_env("REDIS_AUTH_REDIS_POOL_SIZE") || "5")

  def command(command) do
    case Redix.command(:"redix_#{random_index()}", command) do
      {:ok, result} -> result
      {_, message} -> 
        IO.puts message
        nil
    end
  end

  def pipeline(pipeline) do
    case Redix.pipeline(:"redix_#{random_index()}", pipeline) do
      {:ok, result} -> result
      {_, message} -> 
        IO.puts message
        nil
    end
  end

  defp random_index do
    rem(System.unique_integer([:positive]), @redis_instances)
  end
end
