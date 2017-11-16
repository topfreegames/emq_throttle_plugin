defmodule EmqThrottlePlugin.Mixfile do
  use Mix.Project

  def project do
    [
      app: :emq_throttle_plugin,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EmqThrottlePlugin, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:throttle, git: "https://github.com/topfreegames/throttle.git"},
      {:emqttd,
       github: "emqtt/emqttd",
       only: [:test],
       ref: "v2.3-beta.1",
       manager: :make,
       optional: true,
      },
    ]
  end
end
