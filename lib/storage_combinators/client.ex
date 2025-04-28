defmodule StorageCombinators.Client do
  @moduledoc """
  """

  @server StorageCombinators.Server

  @type value :: any()

  @doc """
  Starts the storage server

  ## Examples

      iex> alias StorageCombinators.Impl.MapStore
      iex> {:ok, client} = MapStore.map_store() |> start_link()
      iex> client.put("item", :item)
      iex> client.get("item")
      :item
  """
  def start_link(store) do
    @server.start_link(store)
  end

  @doc """
  Gets a value

  ## Examples

      iex> {:ok, client} = StorageCombinators.Impl.MapStore.map_store() |> StorageCombinators.Client.start_link()
      iex> client.put("item", :item)
      iex> client.get("item")
      :item
      iex> client.fetch("item")

  """
  @spec get(String.t()) :: value() | nil
  def get(ref) do
    GenServer.call(@server, {:get, ref})
  end

  @spec fetch(String.t()) :: {:ok, value()} | :error
  def fetch(ref) do
    GenServer.call(@server, {:fetch, ref})
  end

  def put(ref, value) do
    GenServer.cast(@server, {:put, ref, value})
  end

  def delete(ref) do
    GenServer.cast(@server, {:delete, ref})
  end
end
