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
