defmodule StorageCombinatorsTest.Impl.MapStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Storage

  setup do
    {:ok, store: MapStore.map_store()}
  end

  test "Get on empty MapStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.get(store, 1)

    # Assert
    assert value == nil
  end

  test "Get on empty MapStore doesn't change MapStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.get(store, 1)

    # Assert
    assert store == new_store
  end

  test "Fetch on empty MapStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.fetch(store, 1)

    # Assert
    assert value == {:error, {:no_ref, 1}}
  end

  test "Fetch on empty MapStore doesn't change MapStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.fetch(store, 1)

    # Assert
    assert store == new_store
  end

  test "Putting an item into a MapStore then getting it returns the same value", %{store: store} do
    # Act
    store = Storage.put(store, 1, :one)
    {_store, value} = Storage.get(store, 1)

    assert :one == value
  end

  test "Deleting on an empty MapStore doesn't change the MapStore", %{store: store} do
    # Act
    new_store = Storage.delete(store, 1)

    # Assert
    assert store == new_store
  end

  test "Adding an item to an empty MapStore, then deleting it immediately, returns the empty MapStore",
       %{store: store} do
    # Act
    store_one = Storage.put(store, 1, :one)
    store_two = Storage.delete(store_one, 1)

    # Assert
    assert store == store_two
  end
end
