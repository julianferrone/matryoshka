defmodule MatryoshkaTest.Impl.LogStoreTest do
  use ExUnit.Case, async: true
  alias Matryoshka.Impl.LogStore
  alias Matryoshka.Impl.LogStore.Serialize
  alias Matryoshka.Storage

  @moduletag :tmp_dir

  test "Get on empty LogStore returns nil", %{tmp_dir: tmp_dir} do
    store = LogStore.log_store("#{tmp_dir}/test.log")
    # Act
    {_new_store, value} = Storage.get(store, "item")

    # Assert
    assert value == nil
  end

  test "Get on empty LogStore doesn't change LogStore", %{tmp_dir: tmp_dir} do
    store = LogStore.log_store("#{tmp_dir}/test.log")
    # Act
    {new_store, _value} = Storage.get(store, "item")

    # Assert
    assert store == new_store
  end

  test "Fetch on empty LogStore returns error", %{tmp_dir: tmp_dir} do
    store = LogStore.log_store("#{tmp_dir}/test.log")
    # Act
    {_new_store, value} = Storage.fetch(store, "item")

    # Assert
    assert value == {:error, {:no_ref, "item"}}
  end

  test "Putting an item into a LogStore then getting it returns the same value", %{tmp_dir: tmp_dir} do
    store = LogStore.log_store("#{tmp_dir}/test.log")
    # Act
    store = Storage.put(store, "item", :item)
    {_store, value} = Storage.get(store, "item")

    assert :item == value
  end

  test "Putting additional items into a LogStore doesn't prevent getting earlier values", %{tmp_dir: tmp_dir} do
    store = LogStore.log_store("#{tmp_dir}/test.log")
    # Act
    store = Storage.put(store, "earlier", :earlier)
    store = Storage.put(store, "later", :later)
    {_store, value} = Storage.get(store, "earlier")

    assert :earlier == value
  end

  test "LogStore reads previously added values when re-instantiated", %{tmp_dir: tmp_dir} do
    log_filepath = "#{tmp_dir}/test.log"

    with {:ok, file} <- File.open(log_filepath, [:binary, :write]) do
      Serialize.append_write_log_line(file, "key", :value)
    end

    store = LogStore.log_store(log_filepath)
    dbg(store)
    {_store, value} = Storage.get(store, "key")
    assert value == :value
  end
end
