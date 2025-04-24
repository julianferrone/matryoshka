defmodule StorageCombinators.Impl.CachingStore do
  alias StorageCombinators.Storage
  import StorageCombinators.StorageCombinators, only: [is_storage!: 1]

  @enforce_keys [:main_store, :fast_store]
  defstruct [:main_store, :fast_store]

  @typedoc """
  A struct that implements the StorageCombinators.Storage protocol.
  """
  @type impl_storage :: any()

  @type t :: %__MODULE__{
          main_store: impl_storage(),
          fast_store: impl_storage()
        }

  def caching_store(main_storage, fast_storage)
      when is_struct(main_storage) and is_struct(fast_storage) do
    is_storage!(main_storage)
    is_storage!(fast_storage)
    %__MODULE__{main_store: main_storage, fast_store: fast_storage}
  end

  alias __MODULE__

  defimpl Storage do
    def get(%CachingStore{main_store: main_store, fast_store: fast_store}, ref) do
      case Storage.get(fast_store, ref) do
        {fast_store, nil} ->
          case Storage.get(main_store, ref) do
            {main_store, nil} ->
              {CachingStore.caching_store(main_store, fast_store), nil}

            {main_store, value} ->
              fast_store = Storage.put(fast_store, ref, value)
              {CachingStore.caching_store(main_store, fast_store), value}
          end

        {fast_store, value} ->
          {CachingStore.caching_store(main_store, fast_store), value}
      end
    end

    def put(%CachingStore{main_store: main_store, fast_store: fast_store}, ref, value) do
      main_store = Storage.put(main_store, ref, value)
      fast_store = Storage.put(fast_store, ref, value)
      CachingStore.caching_store(main_store, fast_store)
    end

    def delete(%CachingStore{main_store: main_store, fast_store: fast_store}, ref) do
      main_store = Storage.delete(main_store, ref)
      fast_store = Storage.delete(fast_store, ref)
      CachingStore.caching_store(main_store, fast_store)
    end
  end
end
