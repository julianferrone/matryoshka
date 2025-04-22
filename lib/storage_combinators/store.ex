defmodule StorageCombinators.Store do
  def start_link(server, default) when is_list(default) do
    GenServer.start_link(server, default)
  end

  def get(server, ref) do
    GenServer.call(server, {:get, ref})
  end

  def put(server, ref, value) do
    GenServer.cast(server, {:put, ref, value})
  end

  def patch(server, ref, value) do
    GenServer.cast(server, {:patch, ref, value})
  end

  def delete(server, ref) do
    GenServer.cast(server, {:delete, ref})
  end
end
