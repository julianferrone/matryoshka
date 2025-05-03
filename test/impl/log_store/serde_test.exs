defmodule MatryoshkaTest.Impl.LogStore.SerdeTest do
  alias Matryoshka.Impl.LogStore.Serialize
  alias Matryoshka.Impl.LogStore.Deserialize

  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  test "Serializing then deserializing write log line should be ok" do
    {log_line, _relative_offset, _value_size} = Serialize.format_write_log_line("key", "value")
    {:ok, parsed} = Deserialize.parse_log_line(log_line)
    assert parsed == {:w, "key", "value"}
  end

  test "Serializing then deserializing delete log line should be ok" do
    {log_line, _relative_offset, _value_size} = Serialize.format_delete_log_line("key")
    {:ok, parsed} = Deserialize.parse_log_line(log_line)
    assert parsed == {:d, "key"}
  end

  test "Retrieving indices from log file", %{tmp_dir: tmp_dir} do
    log_filepath = "#{tmp_dir}/test_1.log"
    with {:ok, file} <- File.open(log_filepath, [:binary, :write]) do
      Serialize.append_write_log_line(file, "key", "value")
    end
    assert :error == Deserialize.get_index(log_filepath)
  end
end
