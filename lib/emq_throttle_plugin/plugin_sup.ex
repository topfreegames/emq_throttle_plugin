defmodule EmqThrottlePlugin.Supervisor do
  # Automatically imports Supervisor.Spec
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(children) do
    supervise(children, strategy: :one_for_one)
  end
end

