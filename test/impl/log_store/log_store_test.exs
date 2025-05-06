defmodule MatryoshkaTest.Impl.LogStoreTest do
  use ExUnit.Case, async: true
  alias Matryoshka.Impl.LogStore
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
end
