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
