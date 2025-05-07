defmodule MatryoshkaTest.Impl.LogStore.SerdeTest do
  alias Matryoshka.Impl.LogStore.Encoding
  alias Matryoshka.Impl.LogStore.Serialize
  alias Matryoshka.Impl.LogStore.Deserialize

  use ExUnit.Case, async: true

  test "Serializing then deserializing write log entry should be ok" do
    {log_entry, relative_offset, value_size} = Serialize.format_write_log_entry("key", "value")
    {:ok, parsed} = Deserialize.parse_log_entry(log_entry)
    assert parsed == {:w, "key", "value"}
    assert relative_offset == 27
    assert value_size == 11
  end

  test "Serializing then deserializing delete log entry should be ok" do
    {log_entry, _relative_offset, _value_size} = Serialize.format_delete_log_entry("key")
    {:ok, parsed} = Deserialize.parse_log_entry(log_entry)
    assert parsed == {:d, "key"}
  end

  @tag :tmp_dir
  test "Can retrieve value from log file using index", %{tmp_dir: tmp_dir} do
    log_filepath = "#{tmp_dir}/test_1.log"

    with {:ok, file} <- File.open(log_filepath, [:binary, :write]) do
      Serialize.append_write_log_entry(file, "one", "val_1")
      Serialize.append_write_log_entry(file, "two", "value_2")
    end

    index = Deserialize.get_index(log_filepath)
    {one_offset, one_size} = Map.get(index, "one")
    {two_offset, two_size} = Map.get(index, "two")

    with {:ok, file} <- File.open(log_filepath, [:binary, :read]) do
      {:ok, value} = Deserialize.get_value(file, one_offset, one_size)
      assert value == "val_1"
      {:ok, value} = Deserialize.get_value(file, two_offset, two_size)
      assert value == "value_2"
    end
  end
end
