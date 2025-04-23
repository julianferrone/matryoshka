defmodule StorageCombinators.Mapstore.Impl do
  @enforce_keys [:map]
  defstruct [:map]

  @type t :: %__MODULE__{
          map: Map
        }

  def map_store(), do: map_store(Map.new())
  def map_store(map), do: %__MODULE__{map: map}
end

defimpl StorageCombinators.Storage, for: StorageCombinators.Mapstore.Impl do
  alias StorageCombinators.Mapstore.Impl

  def get(%Impl{map: map}, ref) do
    Map.get(map, ref)
  end

  def put(%Impl{map: map}, ref, value) do
    inner = Map.put(map, ref, value)
    Impl.map_store(inner)
  end

  def delete(%Impl{map: map}, ref) do
    inner = Map.delete(map, ref)
    Impl.map_store(inner)
  end
end
