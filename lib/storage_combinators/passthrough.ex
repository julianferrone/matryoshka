defmodule StorageCombinators.Passthrough do
  @server StorageCombinators.Passthrough.Server

  def start_link(default) when is_list(default) do
    GenServer.start_link(@server, default)
  end

  def get(ref) do
    GenServer.call(@server, {:get, ref})
  end

  def put(ref, value) do
    GenServer.cast(@server, {:put, ref, value})
  end

  def patch(ref, value) do
    GenServer.cast(@server, {:patch, ref, value})
  end

  def delete(ref) do
    GenServer.cast(@server, {:delete, ref})
  end
end

defmodule StorageCombinators.Passthrough.Server do
  use GenServer

  @impl true
  def init(source) do
    {:ok, source}
  end

  @impl true
  def handle_call({:get, ref}, _from, source) do
    response = GenServer.call(source, {:get, ref})
    {:reply, response, source}
  end

  @impl true
  def handle_cast({:put, ref, value}, source) do
    GenServer.cast(source, {:put, ref, value})
    {:noreply, source}
  end

  @impl true
  def handle_cast({:patch, ref, value}, source) do
    GenServer.cast(source, {:patch, ref, value})
    {:noreply, source}
  end

  @impl true
  def handle_cast({:delete, ref, value}, source) do
    GenServer.cast(source, {:delete, ref, value})
    {:noreply, source}
  end
end
