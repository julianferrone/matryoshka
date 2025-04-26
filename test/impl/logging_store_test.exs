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
    {_result, log} = with_log(fn -> Storage.get(store, 1) end)

    # Assert
    assert log =~ "GET 1 => nil"
  end

  test "Get on LoggingStore with value logs value", %{store: store} do
    new_store = Storage.put(store, 1, :one)
    {_store, log} = with_log(fn -> Storage.get(new_store, 1) end)
    assert log =~ "GET 1 => :one"
  end

  test "Fetch on empty LoggingStore logs :error", %{store: store} do
    # Act
    {_result, log} = with_log(fn -> Storage.fetch(store, 1) end)

    # Assert
    assert log =~ "FETCH 1 => :error"
  end

  test "Fetch on LoggingStore with value logs value", %{store: store} do
    new_store = Storage.put(store, 1, :one)
    {_store, log} = with_log(fn -> Storage.fetch(new_store, 1) end)
    assert log =~ "FETCH 1 => {:ok, :one}"
  end

  test "Putting an item into a LoggingStore logs PUT", %{store: store} do
    # Act
    {_store, log} = with_log(fn -> Storage.put(store, 1, :one) end)

    assert log =~ "PUT 1 <= :one"
  end

  test "Deleting on an empty LoggingStore logs DELETE", %{store: store} do
    # Act
    {_store, log} = with_log(fn -> Storage.delete(store, 1) end)

    # Assert
    assert log =~ "DELETE 1"
  end
end
