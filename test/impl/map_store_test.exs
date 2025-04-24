defmodule StorageCombinatorsTest.Impl.MapStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Storage

  test "Get on empty MapStore returns nil" do
    # Arrange
    store = MapStore.map_store()

    # Act
    {_new_store, value} = Storage.get(store, 1)

    # Assert
    assert value == nil
  end

  test "Get on empty MapStore doesn't change MapStore" do
    # Arrange
    store = MapStore.map_store()

    # Act
    {new_store, _value} = Storage.get(store, 1)

    # Assert
    assert store == new_store
  end
end
