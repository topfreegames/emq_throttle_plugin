defmodule EmqThrottlePlugin.Supervisor do
  # Automatically imports Supervisor.Spec
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(children) do
    if Process.whereis(Redix) == nil do
      host = System.get_env("REDIS_AUTH_REDIS_HOST") || "localhost"
      port = String.to_integer(System.get_env("REDIS_AUTH_REDIS_PORT") || "6379")
      password = System.get_env("REDIS_AUTH_REDIS_PASSWORD") || nil
      pool_size = String.to_integer(System.get_env("REDIS_AUTH_REDIS_POOL_SIZE") || "5")
      redix_workers = for i <- 0..(pool_size - 1) do
        worker(Redix, [
          [host: host, port: port, password: password],
          [name: :"redix_#{i}"]
        ], id: {Redix, i})
      end

      supervise(children ++ redix_workers, strategy: :one_for_one)
    end
  end
end
