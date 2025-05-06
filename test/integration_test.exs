defmodule MatryoshkaTest.IntegrationTest do
  use ExUnit.Case, async: true

  import Matryoshka
  doctest Matryoshka

  setup do
    {:ok, storage_server} = map_store() |> start_link()
    {:ok, storage_server: storage_server}
  end

  test "Client gets nil from empty storage server", %{storage_server: storage_server} do
    assert get(storage_server, 1) == nil
  end

  test "Client fetches :error from empty storage server", %{storage_server: storage_server} do
    assert fetch(storage_server, 1) == {:error, {:no_ref, 1}}
  end

  test "Client puts and gets same item from storage server", %{storage_server: storage_server} do
    put(storage_server, 1, :one)
    assert get(storage_server, 1) == :one
  end

  test "Client puts and fetches same item from storage server", %{storage_server: storage_server} do
    put(storage_server, 1, :one)
    assert fetch(storage_server, 1) == {:ok, :one}
  end

  test "Client gets nil after deleting item from storage server", %{storage_server: storage_server} do
    put(storage_server, 1, :one)
    assert get(storage_server, 1) == :one
    delete(storage_server, 1)
    assert get(storage_server, 1) == nil
  end

  test "Client fetches :error after deleting item from storage server", %{storage_server: storage_server} do
    put(storage_server, 1, :one)
    assert fetch(storage_server, 1) == {:ok, :one}
    delete(storage_server, 1)
    assert fetch(storage_server, 1) == {:error, {:no_ref, 1}}
  end
end
