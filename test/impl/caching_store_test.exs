defmodule StorageCombinatorsTest.Impl.CachingStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.CachingStore
  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Storage

  setup do
    [
      empty: CachingStore.caching_store(MapStore.map_store(), MapStore.map_store()),
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
end
