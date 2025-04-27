defmodule StorageCombinatorsTest.Impl.MapStoreTest do
  alias StorageCombinators.Storage
  alias StorageCombinators.Impl.MapStore

  use ExUnit.Case, async: true
  doctest MapStore

  setup do
    {:ok, store: MapStore.map_store()}
  end

  test "Get on empty MapStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.get(store, "item")

    # Assert
    assert value == nil
  end

  test "Get on empty MapStore doesn't change MapStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.get(store, "item")

    # Assert
    assert store == new_store
  end

  test "Fetch on empty MapStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.fetch(store, "item")

    # Assert
    assert value == {:error, {:no_ref, "item"}}
  end

  test "Fetch on empty MapStore doesn't change MapStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.fetch(store, "item")

    # Assert
    assert store == new_store
  end

  test "Putting an item into a MapStore then getting it returns the same value", %{store: store} do
    # Act
    store = Storage.put(store, "item", :item)
    {_store, value} = Storage.get(store, "item")

    assert :item == value
  end

  test "Deleting on an empty MapStore doesn't change the MapStore", %{store: store} do
    # Act
    new_store = Storage.delete(store, "item")

    # Assert
    assert store == new_store
  end

  test "Adding an item to an empty MapStore, then deleting it immediately, returns the empty MapStore",
       %{store: store} do
    # Act
    store_one = Storage.put(store, "item", :item)
    store_two = Storage.delete(store_one, "item")

    # Assert
    assert store == store_two
  end
end
