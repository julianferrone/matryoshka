defmodule StorageCombinatorsTest.IntegrationTest do
  use ExUnit.Case, async: true

  alias Erl2exVendored.Pipeline.ExFunc
  alias StorageCombinators.Impl.MapStore
  alias StorageCombinators.Client

  setup do
    store = MapStore.map_store()
    {:ok, storage_server} = Client.start_link(store)
    {:ok, storage_server: storage_server}
  end

  test "Client gets nil from empty storage server" do
    assert Client.get(1) == nil
  end

  test "Client fetches :error from empty storage server" do
    assert Client.fetch(1) == :error
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
    assert Client.fetch(1) == :error
  end
end
