defmodule StorageCombinators.MapStore do
  alias StorageCombinators.Client
  @server StorageCombinators.MapClient.Server

  def start_link(default) when is_list(default), do: Client.start_link(@server, default)

  def get(ref), do: Client.get(@server, ref)

  def put(ref, value), do: Client.put(@server, ref, value)

  def patch(ref, value), do: Client.patch(@server, ref, value)

  def delete(ref), do: Client.delete(@server, ref)
end
