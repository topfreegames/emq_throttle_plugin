# EmqThrottlePlugin

Throttling messages for the EMQ Broker.

## Installation

The package can be installed by adding `emq_throttle_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:emq_throttle_plugin, git: "git://github.com/topfreegames/emq_throttle_plugin.git"}
  ]
end
```

## Plug the plugin

To add the plugin on emqtt, clone emq-relx project and add:
- DEPS += emq_throttle_plugin on Makefile
- dep_emq_throttle_plugin = git https://github.com/topfreegames/emq_throttle_plugin.git *VERSION_OR_BRANCH* on Makefile
- {emq_throttle_plugin, load} on relx.config

Then run `rm -rf _rel deps rel && make`
