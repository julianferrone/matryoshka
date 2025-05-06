defmodule Matryoshka.Server do
  use GenServer

  alias Matryoshka.Storage
  alias Matryoshka.IsStorage

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(store) do
    IsStorage.is_storage!(store)
    {:ok, store}
  end

  @impl true
  def handle_call({:get, ref}, _from, store) do
    {store, value} = Storage.get(store, ref)
    {:reply, value, store}
  end

  @impl true
  def handle_call({:fetch, ref}, _from, store) do
    {store, value} = Storage.fetch(store, ref)
    {:reply, value, store}
  end

  @impl true
  def handle_cast({:put, ref, value}, store) do
    {:noreply, Storage.put(store, ref, value)}
  end

  @impl true
  def handle_cast({:delete, ref}, store) do
    {:noreply, Storage.delete(store, ref)}
  end
end
