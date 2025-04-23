defmodule StorageCombinators.PassThrough.Server do
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
