defmodule EmqThrottlePlugin.Shared do
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :mqtt_client, extract(:mqtt_client, from_lib: "emqttd/include/emqttd.hrl")
end
