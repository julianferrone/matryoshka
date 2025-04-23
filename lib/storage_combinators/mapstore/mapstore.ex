defmodule StorageCombinators.MapStore do
  alias StorageCombinators.Store
  @server StorageCombinators.MapStore.Server

  def start_link(default) when is_list(default), do: Store.start_link(@server, default)

  def get(ref), do: Store.get(@server, ref)

  def put(ref, value), do: Store.put(@server, ref, value)

  def patch(ref, value), do: Store.patch(@server, ref, value)

  def delete(ref), do: Store.delete(@server, ref)
end
