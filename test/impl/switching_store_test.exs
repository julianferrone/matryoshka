defmodule StorageCombinatorsTest.Impl.SwitchingStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.SwitchingStore
  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Storage

  setup do
    [
      store:
        SwitchingStore.switching_store(%{
          "one" => MapStore.map_store(),
          "two" => MapStore.map_store(%{"test" => :test})
        })
    ]
  end

  test "Get on SwitchingStore with empty substore returns nil", %{store: store} do
    {_new_store, value} = Storage.get(store, "one/test")
    assert value == nil
  end

  test "Get on SwitchingStore with value in substore returns value", %{store: store} do
    {_new_store, value} = Storage.get(store, "two/test")
    assert value == :test
  end

  test "Fetch on SwitchingStore with empty substore returns :error", %{store: store} do
    {_new_store, value} = Storage.fetch(store, "one/test")
    assert value == :error
  end

  test "Fetch on SwitchingStore with value in substore returns value", %{store: store} do
    {_new_store, value} = Storage.fetch(store, "two/test")
    assert value == {:ok, :test}
  end

  test "Putting value into SwitchingStore, then getting with same reference, returns same value",
       %{store: store} do
    new_store = Storage.put(store, "one/item", :item)
    {_store, value} = Storage.get(new_store, "one/item")
    assert value == :item
  end

  test "Putting value into SwitchingStore, then fetching with same reference, returns same value",
       %{store: store} do
    new_store = Storage.put(store, "one/item", :item)
    {_store, value} = Storage.fetch(new_store, "one/item")
    assert value == {:ok, :item}
  end

  test "Cannot get value from SwitchingStore after deleting", %{store: store} do
    new_store = Storage.put(store, "one/item", :item)
    {new_store, value} = Storage.get(new_store, "one/item")
    assert value == :item
    new_store = Storage.delete(new_store, "one/item")
    {_new_store, value} = Storage.get(new_store, "one/item")
    assert value == nil
  end

  test "Cannot fetch value from SwitchingStore after deleting", %{store: store} do
    new_store = Storage.put(store, "one/item", :item)
    {new_store, value} = Storage.fetch(new_store, "one/item")
    assert value == {:ok, :item}
    new_store = Storage.delete(new_store, "one/item")
    {_new_store, value} = Storage.fetch(new_store, "one/item")
    assert value == :error
  end

  test "Cannot get value from SwitchingStore if reference is too short", %{store: store} do
    {new_store, value} = Storage.get(store, "one")
    assert value == nil
  end

  test "Cannot fetch value from SwitchingStore if reference is too short", %{store: store} do
    {new_store, value} = Storage.fetch(store, "one")
    assert value == :error
  end
end
