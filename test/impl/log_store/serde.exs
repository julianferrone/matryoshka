defmodule MatryoshkaTest.Impl.LogStore.Test do
  alias Matryoshka.Impl.LogStore.Serialize
  alias Matryoshka.Impl.LogStore.Deserialize

  use ExUnit.Case, async: true

  test "Serializing then deserializing write log line should be ok" do
    log_line = Serialize.format_write_log_line("key", "value")
    {:ok, parsed} = Deserialize.parse_log_line(log_line)
    assert parsed == {:w, "key", "value"}
  end

  test "Serializing then deserializing delete log line should be ok" do
    log_line = Serialize.format_delete_log_line("key")
    {:ok, parsed} = Deserialize.parse_log_line(log_line)
    assert parsed == {:d, "key"}
  end
end
