defmodule StorageCombinatorsTest.Impl.CachingStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.CachingStore
  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Storage

  setup do
    [
      empty: MapStore.map_store() |> CachingStore.caching_store(),
      full:
        CachingStore.caching_store(
          MapStore.map_store(%{1 => :one, 2 => :two}),
          MapStore.map_store(%{3 => :three, 4 => :four})
        )
    ]
  end

  test "Get on empty CachingStore returns nil", context do
    # Arrange
    store = context[:empty]

    # Act
    {_new_store, value} = Storage.get(store, 1)

    # Assert
    assert value == nil
  end

  test "Get on CachingStore main store returns value", context do
    # Arrange
    store = context[:full]

    # Act
    {_new_store, value} = Storage.get(store, 1)

    # Assert
    assert value == :one
  end

  test "Get on CachingStore fast store returns value", context do
    # Arrange
    store = context[:full]

    # Act
    {_new_store, value} = Storage.get(store, 3)

    # Assert
    assert value == :three
  end

  test "Get on CachingStore—that has no value in fast store—changes store", context do
    store = context[:full]
    {new_store, _value} = Storage.get(store, 1)
    refute store == new_store
  end

  test "Putting a value into a CachingStore, then getting it, gives the same value", context do
    store = context[:empty]
    new_store = Storage.put(store, 5, :five)
    {_store, value} = Storage.get(new_store, 5)
    assert value == :five
  end

  test "Fetch on empty CachingStore returns :error", context do
    # Arrange
    store = context[:empty]

    # Act
    {_new_store, value} = Storage.fetch(store, 1)

    # Assert
    assert value == :error
  end

  test "Fetch on CachingStore main store returns {:ok, value}", context do
    # Arrange
    store = context[:full]

    # Act
    {_new_store, value} = Storage.fetch(store, 1)

    # Assert
    assert value == {:ok, :one}
  end

  test "Fetch on CachingStore fast store returns {:ok, value}", context do
    # Arrange
    store = context[:full]

    # Act
    {_new_store, value} = Storage.fetch(store, 3)

    # Assert
    assert value == {:ok, :three}
  end

  test "Fetch on CachingStore main store changes store", context do
    store = context[:full]
    {new_store, _value} = Storage.fetch(store, 1)
    refute store == new_store
  end

  test "Putting a value into a CachingStore, then fetching it, gives the same value", context do
    store = context[:empty]
    new_store = Storage.put(store, 5, :five)
    {_store, value} = Storage.fetch(new_store, 5)
    assert value == {:ok, :five}
  end
end
