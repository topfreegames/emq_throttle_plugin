defmodule EmqThrottlePlugin.Utils do
  def to_bool(nil), do: false
  def to_bool(v), do: String.to_existing_atom(v)

  def to_int(nil), do: 0
  def to_int(v), do: String.to_integer(v)
end
