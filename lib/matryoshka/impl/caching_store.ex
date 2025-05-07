defmodule Matryoshka.Impl.CachingStore do
  alias Matryoshka.IsStorage
  alias Matryoshka.Storage
  import Matryoshka.Impl.MapStore, only: [map_store: 0]

  @enforce_keys [:main_store, :cache_store]
  defstruct [:main_store, :cache_store]

  @type t :: %__MODULE__{
          main_store: IsStorage.t(),
          cache_store: IsStorage.t()
        }

  @doc """
  Create a CachingStore using a MapStore as the fast cache store.
  """
  def caching_store(main_store), do: caching_store(main_store, map_store())

  @doc """
  Create a CachingStore from a main store (which is the source of truth for all
  data ) and a fast store (which will cache the results from the main store).
  """
  def caching_store(main_store, cache_store)
      when is_struct(main_store) and is_struct(cache_store) do
    IsStorage.is_storage!(main_store)
    IsStorage.is_storage!(cache_store)
    %__MODULE__{main_store: main_store, cache_store: cache_store}
  end

  alias __MODULE__

  defimpl Storage do
    def fetch(store, ref) do
      {cache_store_new, val_fast} = Storage.fetch(store.cache_store, ref)

      case val_fast do
        {:ok, _value} ->
          new_store = %{store | cache_store: cache_store_new}
          {new_store, val_fast}

        {:error, _reason_fast} ->
          {main_store_new, val_main} = Storage.fetch(store.main_store, ref)

          case val_main do
            {:ok, value} ->
              cache_store_new = Storage.put(cache_store_new, ref, value)
              new_store = CachingStore.caching_store(main_store_new, cache_store_new)
              {new_store, val_main}

            {:error, reason} ->
              {store, {:error, reason}}
          end
      end
    end

    def get(store, ref) do
      {cache_store_new, val_fast} = Storage.get(store.cache_store, ref)

      case val_fast do
        nil ->
          {main_store_new, val_main} = Storage.get(store.main_store, ref)

          case val_main do
            nil ->
              store_new = CachingStore.caching_store(main_store_new, cache_store_new)
              {store_new, nil}

            value ->
              cache_store_new = Storage.put(cache_store_new, ref, value)
              store_new = CachingStore.caching_store(main_store_new, cache_store_new)
              {store_new, value}
          end

        value ->
          store_new = %{store | cache_store: cache_store_new}
          {store_new, value}
      end
    end

    def put(store, ref, value) do
      main_store = Storage.put(store.main_store, ref, value)
      cache_store = Storage.put(store.cache_store, ref, value)
      CachingStore.caching_store(main_store, cache_store)
    end

    def delete(store, ref) do
      main_store = Storage.delete(store.main_store, ref)
      cache_store = Storage.delete(store.cache_store, ref)
      CachingStore.caching_store(main_store, cache_store)
    end
  end
end
