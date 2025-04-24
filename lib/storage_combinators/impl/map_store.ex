defmodule StorageCombinators.Impl.MapStore do
  @enforce_keys [:map]
  defstruct [:map]

  @type t :: %__MODULE__{
          map: Map
        }

  def map_store(), do: map_store(Map.new())
  def map_store(map), do: %__MODULE__{map: map}

  alias __MODULE__

  defimpl StorageCombinators.Storage do
    def get(%MapStore{map: map} = store, ref) do
      {store, Map.get(map, ref)}
    end

    def put(%MapStore{map: map}, ref, value) do
      inner = Map.put(map, ref, value)
      MapStore.map_store(inner)
    end

    def delete(%MapStore{map: map}, ref) do
      inner = Map.delete(map, ref)
      MapStore.map_store(inner)
    end
  end
end
