defmodule StorageCombinators.PassThrough.Client do
  alias StorageCombinators.Client, as: ScClient
  @server StorageCombinators.PassThrough.Server

  def start_link(default) when is_list(default), do: ScClient.start_link(@server, default)

  def get(ref), do: ScClient.get(@server, ref)

  def put(ref, value), do: ScClient.put(@server, ref, value)

  def patch(ref, value), do: ScClient.patch(@server, ref, value)

  def delete(ref), do: ScClient.delete(@server, ref)
end
