defmodule StorageCombinatorsTest.Impl.MapStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Storage

  test "Get on empty MapStore returns nil" do
    # Arrange
    store = MapStore.map_store()

    # Act
    {_new_store, value} = Storage.Get.get(store, 1)

    # Assert
    assert value == nil
  end

  test "Get on empty MapStore doesn't change MapStore" do
    # Arrange
    store = MapStore.map_store()

    # Act
    {new_store, _value} = Storage.Get.get(store, 1)

    # Assert
    assert store == new_store
  end

  test "Putting an item into a MapStore then getting it returns the same value" do
    # Arrange
    store = MapStore.map_store()

    # Act
    store = Storage.put(store, 1, :one)
    {_store, value} = Storage.Get.get(store, 1)

    assert :one == value
  end

  test "Deleting on an empty MapStore doesn't change the MapStore" do
    # Arrange
    store = MapStore.map_store()

    # Act
    new_store = Storage.delete(store, 1)

    # Assert
    assert store == new_store
  end

  test "Adding an item to an empty MapStore, then deleting it immediately, returns the empty MapStore" do
    # Arrange
    store = MapStore.map_store()

    # Act
    store_one = Storage.put(store, 1, :one)
    store_two = Storage.delete(store_one, 1)

    # Assert
    assert store == store_two
  end
end
