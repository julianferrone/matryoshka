defmodule StorageCombinators.MapStore.Server do
  use GenServer
  alias StorageCombinators.MapStore.Impl

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(source) do
    {:ok, source}
  end

  @impl true
  def handle_call({:get, ref}, _from, map) do
    {value, map} = Impl.get(map, ref)
    {:reply, value, map}
  end

  @impl true
  def handle_cast({:put, ref, value}, map) do
    {:noreply, Impl.put(map, ref, value)}
  end

  @impl true
  def handle_cast({:patch, ref, value}, map) do
    {:noreply, Impl.patch(map, ref, value)}
  end

  @impl true
  def handle_cast({:delete, ref}, map) do
    {:noreply, Impl.delete(map, ref)}
  end
end
