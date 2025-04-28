defmodule StorageCombinatorsTest.IntegrationTest do
  use ExUnit.Case, async: true

  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Client

  setup do
    {:ok, storage_server} = MapStore.map_store() |> Client.start_link
    {:ok, storage_server: storage_server}
  end

  test "Client gets nil from empty storage server" do
    assert Client.get(1) == nil
  end

  test "Client fetches :error from empty storage server" do
    assert Client.fetch(1) == {:error, {:no_ref, 1}}
  end

  test "Client puts and gets same item from storage server" do
    Client.put(1, :one)
    assert Client.get(1) == :one
  end

  test "Client puts and fetches same item from storage server" do
    Client.put(1, :one)
    assert Client.fetch(1) == {:ok, :one}
  end

  test "Client gets nil after deleting item from storage server" do
    Client.put(1, :one)
    assert Client.get(1) == :one
    Client.delete(1)
    assert Client.get(1) == nil
  end

  test "Client fetches :error after deleting item from storage server" do
    Client.put(1, :one)
    assert Client.fetch(1) == {:ok, :one}
    Client.delete(1)
    assert Client.fetch(1) == {:error, {:no_ref, 1}}
  end
end
