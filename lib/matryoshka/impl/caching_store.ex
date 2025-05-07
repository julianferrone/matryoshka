defmodule Matryoshka.Impl.CachingStore do
  alias Matryoshka.IsStorage
  alias Matryoshka.Storage
  import Matryoshka.Impl.MapStore, only: [map_store: 0]

  @enforce_keys [:main_store, :fast_store]
  defstruct [:main_store, :fast_store]

  @type t :: %__MODULE__{
          main_store: IsStorage.t(),
          fast_store: IsStorage.t()
        }

  @doc """
  Create a CachingStore using a MapStore as the fast cache store.
  """
  def caching_store(main_storage), do: caching_store(main_storage, map_store())

  @doc """
  Create a CachingStore from a main store (which is the source of truth for all
  data ) and a fast store (which will cache the results from the main store).
  """
  def caching_store(main_storage, fast_storage)
      when is_struct(main_storage) and is_struct(fast_storage) do
    IsStorage.is_storage!(main_storage)
    IsStorage.is_storage!(fast_storage)
    %__MODULE__{main_store: main_storage, fast_store: fast_storage}
  end

  alias __MODULE__

  defimpl Storage do
    def fetch(store, ref) do
      {fast_store_new, val_fast} = Storage.fetch(store.fast_store, ref)

      case val_fast do
        {:ok, _value} ->
          new_store = %{store | fast_store: fast_store_new}
          {new_store, val_fast}

        {:error, _reason_fast} ->
          {main_store_new, val_main} = Storage.fetch(store.main_store, ref)

          case val_main do
            {:ok, value} ->
              fast_store_new = Storage.put(fast_store_new, ref, value)
              new_store = CachingStore.caching_store(main_store_new, fast_store_new)
              {new_store, val_main}

            {:error, reason} ->
              {store, {:error, reason}}
          end
      end
    end

    def get(store, ref) do
      {fast_store_new, val_fast} = Storage.get(store.fast_store, ref)

      case val_fast do
        nil ->
          {main_store_new, val_main} = Storage.get(store.main_store, ref)

          case val_main do
            nil ->
              store_new = CachingStore.caching_store(main_store_new, fast_store_new)
              {store_new, nil}

            value ->
              fast_store_new = Storage.put(fast_store_new, ref, value)
              store_new = CachingStore.caching_store(main_store_new, fast_store_new)
              {store_new, value}
          end

        value ->
          store_new = %{store | fast_store: fast_store_new}
          {store_new, value}
      end
    end

    def put(store, ref, value) do
      main_store = Storage.put(store.main_store, ref, value)
      fast_store = Storage.put(store.fast_store, ref, value)
      CachingStore.caching_store(main_store, fast_store)
    end

    def delete(store, ref) do
      main_store = Storage.delete(store.main_store, ref)
      fast_store = Storage.delete(store.fast_store, ref)
      CachingStore.caching_store(main_store, fast_store)
    end
  end
end
