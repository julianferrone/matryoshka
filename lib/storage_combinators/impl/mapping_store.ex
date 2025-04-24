defmodule StorageCombinators.Impl.MappingStore do
  import StorageCombinators.StorageCombinators, only: [is_storage!: 1]

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
    is_storage!(inner)
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
    @spec fetch(MappingStore.t(), StorageCombinators.Reference) :: any()
    def fetch(
          %MappingStore{inner: inner, map_ref: map_ref, map_retrieved: map_retrieved} = store,
          ref
        ) do
      {inner_new, value} = StorageCombinators.Storage.fetch(inner, map_ref.(ref))
      {%{store|inner: inner_new}, map_retrieved.(value)}
    end

    def get(
          %MappingStore{inner: inner, map_ref: map_ref, map_retrieved: map_retrieved} = store,
          ref
        ) do
      {inner_new, value} = StorageCombinators.Storage.get(inner, map_ref.(ref))

      {%{store|inner: inner_new}, map_retrieved.(value)}
    end

    def put(
          %MappingStore{inner: inner, map_ref: map_ref, map_to_store: map_to_store} = store,
          ref,
          value
        ) do
      inner_new = StorageCombinators.Storage.put(inner, map_ref.(ref), map_to_store.(value))
      %{store | inner: inner_new}
    end

    def delete(%MappingStore{inner: inner, map_ref: map_ref} = store, ref) do
      inner_new = StorageCombinators.Storage.delete(inner, map_ref.(ref))
      %{store | inner: inner_new}
    end
  end
end
