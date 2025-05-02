defmodule StorageCombinatorsTest.Impl.FilesystemStoreTest do
  alias StorageCombinators.Storage
  alias StorageCombinators.Impl.FilesystemStore

  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  test "Get on empty MapStore returns nil", %{tmp_dir: tmp_dir} do
    store = FilesystemStore.filesystem_store(tmp_dir)

    # Act
    {_new_store, value} = Storage.get(store, "item")

    # Assert
    assert value == nil
  end

  test "Get on empty MapStore doesn't change MapStore", %{tmp_dir: tmp_dir} do
    # Act
    store = FilesystemStore.filesystem_store(tmp_dir)
    {new_store, _value} = Storage.get(store, "item")

    # Assert
    assert store == new_store
  end

  test "Fetch on empty MapStore returns nil", %{tmp_dir: tmp_dir} do
    # Act
    store = FilesystemStore.filesystem_store(tmp_dir)
    {_new_store, value} = Storage.fetch(store, "item")

    # Assert
    assert value == {:error, {:no_ref, "item"}}
  end

  test "Fetch on empty MapStore doesn't change MapStore", %{tmp_dir: tmp_dir} do
    # Act
    store = FilesystemStore.filesystem_store(tmp_dir)
    {new_store, _value} = Storage.fetch(store, "item")

    # Assert
    assert store == new_store
  end

  test "Putting an item into a MapStore then getting it returns the same value", %{
    tmp_dir: tmp_dir
  } do
    # Act
    store = FilesystemStore.filesystem_store(tmp_dir)
    store = Storage.put(store, "item", "item")
    {_store, value} = Storage.get(store, "item")

    assert "item" == value
  end

  test "Deleting on an empty MapStore doesn't change the MapStore", %{tmp_dir: tmp_dir} do
    # Act
    store = FilesystemStore.filesystem_store(tmp_dir)
    new_store = Storage.delete(store, "item")

    # Assert
    assert store == new_store
  end

  test "Adding an item to an empty MapStore, then deleting it immediately, returns the empty MapStore",
       %{tmp_dir: tmp_dir} do
    store = FilesystemStore.filesystem_store(tmp_dir)
    # Act
    store_one = Storage.put(store, "item", "item")
    store_two = Storage.delete(store_one, "item")

    # Assert
    assert store == store_two
  end
end
