defmodule EmqThrottlePlugin.Redis do
  require Logger

  @redis_instances String.to_integer(System.get_env("REDIS_AUTH_REDIS_POOL_SIZE") || "5")

  @doc """
  Executes a redis command. If an error occurred, log error and returns nil.
  Otherwise returns the result of the command.
  """
  def command(command) do
    case Redix.command(:"redix_#{random_index()}", command) do
      {:ok, result} -> result
      {_, message} -> 
        Logger.error fn ->
          "redis error: #{message}"
        end
        nil
    end
  end

  @doc """
  Executes a redis pipeline. If an error occurred, log error and returns nil.
  Otherwise returns the result of the command.
  """
  def pipeline(pipeline) do
    case Redix.pipeline(:"redix_#{random_index()}", pipeline) do
      {:ok, result} -> result
      {_, message} -> 
        Logger.error fn ->
          "redis error: #{message}"
        end
        nil
    end
  end

  defp random_index do
    rem(System.unique_integer([:positive]), @redis_instances)
  end
end
