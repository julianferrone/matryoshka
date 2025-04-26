defmodule StorageCombinators.Client do
  @server StorageCombinators.Server

  def start_link(default) do
    @server.start_link(default)
  end

  def get(ref) do
    GenServer.call(@server, {:get, ref})
  end

  def fetch(ref) do
    GenServer.call(@server, {:fetch, ref})
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

I
