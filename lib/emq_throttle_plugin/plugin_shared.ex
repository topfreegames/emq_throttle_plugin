defmodule EmqThrottlePlugin.Shared do
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :mqtt_client, extract(:mqtt_client, from_lib: "emqttd/include/emqttd.hrl")
  defrecord :mqtt_session, extract(:mqtt_session, from_lib: "emqttd/include/emqttd.hrl")
  defrecord :state, [:auth_cmd, :super_cmd, :hash_type]
end
