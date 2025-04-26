defmodule StorageCombinatorsTest.LoggingStoreTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  require Logger

  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Impl.LoggingStore
  alias StorageCombinators.Storage

  @moduletag capture_log: true

  setup do
    store = MapStore.map_store() |> LoggingStore.logging_store()
    {:ok, store: store}
  end

  test "Get on empty LoggingStore logs nil", %{store: store} do
    # Act
    {_result, log} = with_log(fn -> Storage.get(store, "item") end)

    # Assert
    assert log =~ "GET \"item\" => nil"
  end

  test "Get on LoggingStore with value logs value", %{store: store} do
    new_store = Storage.put(store, "item", :item)
    {_store, log} = with_log(fn -> Storage.get(new_store, "item") end)
    assert log =~ "GET \"item\" => :item"
  end

  test "Fetch on empty LoggingStore logs :error", %{store: store} do
    # Act
    {_result, log} = with_log(fn -> Storage.fetch(store, "item") end)

    # Assert
    assert log =~ "FETCH \"item\" => {:error, {:no_ref, \"item\"}}"
  end

  test "Fetch on LoggingStore with value logs value", %{store: store} do
    new_store = Storage.put(store, "item", :item)
    {_store, log} = with_log(fn -> Storage.fetch(new_store, "item") end)
    assert log =~ "FETCH \"item\" => {:ok, :item}"
  end

  test "Putting an item into a LoggingStore logs PUT", %{store: store} do
    # Act
    {_store, log} = with_log(fn -> Storage.put(store, "item", :item) end)

    assert log =~ "PUT \"item\" <= :item"
  end

  test "Deleting on an empty LoggingStore logs DELETE", %{store: store} do
    # Act
    {_store, log} = with_log(fn -> Storage.delete(store, "item") end)

    # Assert
    assert log =~ "DELETE \"item\""
  end
end
