defmodule StorageCombinators.MapStore do
  alias StorageCombinators.Store
  @server StorageCombinators.MapStore.Server

  def start_link(default) when is_list(default), do: Store.start_link(@server, default)

  def get(ref), do: Store.get(@server, ref)

  def put(ref, value), do: Store.put(@server, ref, value)

  def patch(ref, value), do: Store.patch(@server, ref, value)

  def delete(ref), do: Store.delete(@server, ref)
end

defmodule StorageCombinators.MapStore.Server do
  use GenServer
  alias StorageCombinators.MapStore.Impl

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

defmodule StorageCombinators.MapStore.Impl do
  alias StorageCombinators.Patch

  def get(map, ref), do: Map.get(map, ref)
  def put(map, ref, value), do: Map.put(map, ref, value)

  def patch(map, ref, value) do
    first = Map.get(map, ref)
    patched = Patch.patch(first, value)
    Map.replace(map, ref, patched)
  end

  def delete(map, ref), do: Map.delete(map, ref)
end
