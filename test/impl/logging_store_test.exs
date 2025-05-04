defmodule MatryoshkaTest.LoggingStoreTest do
  import ExUnit.CaptureLog
  require Logger

  alias Matryoshka.Impl.MapStore
  alias Matryoshka.Impl.LoggingStore
  alias Matryoshka.Storage

  use ExUnit.Case, async: true
  doctest LoggingStore

  @moduletag capture_log: true

  setup do
    store = MapStore.map_store() |> LoggingStore.logging_store()
    {:ok, store: store}
  end

  test "Get on empty LoggingStore logs nil", %{store: store} do
    # Act
    {_result, log} = with_log(fn -> Storage.get(store, "item") end)

    # Assert
    assert log =~ "[request: \"GET\", ref: \"item\", value: nil]"
  end

  test "Get on LoggingStore with value logs value", %{store: store} do
    new_store = Storage.put(store, "item", :item)
    {_store, log} = with_log(fn -> Storage.get(new_store, "item") end)
    assert log =~ "[request: \"GET\", ref: \"item\", value: :item]"
  end

  test "Fetch on empty LoggingStore logs :error", %{store: store} do
    # Act
    {_result, log} = with_log(fn -> Storage.fetch(store, "item") end)

    # Assert
    assert log =~ "[request: \"FETCH\", ref: \"item\", value: {:error, {:no_ref, \"item\"}}]"
  end

  test "Fetch on LoggingStore with value logs value", %{store: store} do
    new_store = Storage.put(store, "item", :item)
    {_store, log} = with_log(fn -> Storage.fetch(new_store, "item") end)
    assert log =~ "[request: \"FETCH\", ref: \"item\", value: {:ok, :item}]"
  end

  test "Putting an item into a LoggingStore logs PUT", %{store: store} do
    # Act
    {_store, log} = with_log(fn -> Storage.put(store, "item", :item) end)

    assert log =~ "[request: \"PUT\", ref: \"item\", value: :item]"
  end

  test "Deleting on an empty LoggingStore logs DELETE", %{store: store} do
    # Act
    {_store, log} = with_log(fn -> Storage.delete(store, "item") end)

    # Assert
    assert log =~ "[request: \"DELETE\", ref: \"item\"]"
  end
end
