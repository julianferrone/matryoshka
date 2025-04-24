defmodule StorageCombinators.MappingStore do
  @enforce_keys [:inner]
  defstruct [
    :inner,
    map_ref: &Function.identity/1,
    map_retrieved: &Function.identity/1,
    map_to_store: &Function.identity/1
  ]

  @typedoc """
  A struct that implements the StorageCombinators.Storage protocol.
  """
  @type impl_storage :: any()

  @type t :: %__MODULE__{
          inner: impl_storage,
          map_ref: (StorageCombinators.Reference -> StorageCombinators.Reference),
          map_retrieved: (any() -> any()),
          map_to_store: (any() -> any())
        }

  @identity &Function.identity/1

  def mapping_store(inner, opts \\ []) do
    map_ref = Keyword.get(opts, :map_ref, @identity)
    map_retrieved = Keyword.get(opts, :map_retrieved, @identity)
    map_to_store = Keyword.get(opts, :map_to_store, @identity)

    %__MODULE__{
      inner: inner,
      map_ref: map_ref,
      map_retrieved: map_retrieved,
      map_to_store: map_to_store
    }
  end

  alias __MODULE__

  defimpl StorageCombinators.Storage do
    @spec get(MappingStore.t(), StorageCombinators.Reference) :: any()
    def get(%MappingStore{inner: inner, map_ref: map_ref, map_retrieved: map_retrieved}, ref) do
      ref = map_ref.(ref)
      value = StorageCombinators.Storage.get(inner, ref)
      map_retrieved.(value)
    end

    def put(%MappingStore{inner: inner, map_ref: map_ref, map_to_store: map_to_store} = store, ref, value) do
      ref = map_ref.(ref)
      value = map_to_store.(value)
      inner = StorageCombinators.Storage.put(inner, ref, value)
      %{store | inner: inner}
    end

    def delete(%MappingStore{inner: inner, map_ref: map_ref} = store, ref) do
      ref = map_ref.(ref)
      inner = StorageCombinators.Storage.delete(inner, ref)
      %{store | inner: inner}
    end
  end
end
