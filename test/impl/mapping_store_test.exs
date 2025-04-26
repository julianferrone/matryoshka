defmodule StorageCombinatorsTest.Impl.MappingStoreTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Impl.MappingStore
  alias StorageCombinators.Storage

  setup do
    {:ok,
     increment_on_insert:
       MapStore.map_store()
       |> MappingStore.mapping_store(map_to_store: fn x -> x + 1 end),
     decrement_on_retrieve:
       MapStore.map_store()
       |> MappingStore.mapping_store(map_retrieved: fn x -> x - 1 end)}
  end

  test "Get on empty MappingStore returns nil", %{
    increment_on_insert: increment_on_insert,
    decrement_on_retrieve: decrement_on_retrieve
  } do
    # Act
    {_new_store, value1} = Storage.get(increment_on_insert, 1)
    {_new_store, value2} = Storage.get(decrement_on_retrieve, 1)

    # Assert
    assert value1 == nil
    assert value2 == nil
  end

  test "Get on empty MappingStore doesn't change MappingStore", %{
    increment_on_insert: increment_on_insert,
    decrement_on_retrieve: decrement_on_retrieve
  } do
    # Act
    {new_ioi, _value} = Storage.get(increment_on_insert, 1)
    {new_dor, _value} = Storage.get(decrement_on_retrieve, 1)

    # Assert
    assert increment_on_insert == new_ioi
    assert decrement_on_retrieve == new_dor
  end

  test "Fetch on empty MappingStore returns nil", %{
    increment_on_insert: increment_on_insert,
    decrement_on_retrieve: decrement_on_retrieve
  } do
    # Act
    {_new_store, value1} = Storage.fetch(increment_on_insert, 1)
    {_new_store, value2} = Storage.fetch(decrement_on_retrieve, 1)

    # Assert
    assert value1 == {:error, {:no_ref, 1}}
    assert value2 == {:error, {:no_ref, 1}}
  end

  test "Fetch on empty MappingStore doesn't change MappingStore", %{
    increment_on_insert: increment_on_insert,
    decrement_on_retrieve: decrement_on_retrieve
  } do
    # Act
    {new_ioi, _value} = Storage.fetch(increment_on_insert, 1)
    {new_dor, _value} = Storage.fetch(decrement_on_retrieve, 1)

    # Assert
    assert increment_on_insert == new_ioi
    assert decrement_on_retrieve == new_dor
  end

  test "Putting an item into a MappingStore that increments on storage, then getting it, returns the same value + 1",
       %{
         increment_on_insert: increment_on_insert
       } do
    # Act
    increment_on_insert = Storage.put(increment_on_insert, :one, 1)
    {_new_ioi, value} = Storage.get(increment_on_insert, :one)

    assert value == 2
  end

  test "Putting an item into a MappingStore that decrements on retrieval, then getting it, returns the same value - 1",
       %{
        decrement_on_retrieve: decrement_on_retrieve
       } do
    # Act
    decrement_on_retrieve = Storage.put(decrement_on_retrieve, :one, 1)
    {_new_dor, value} = Storage.get(decrement_on_retrieve, :one)

    assert value == 0
  end
end
