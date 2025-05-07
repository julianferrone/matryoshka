defmodule Matryoshka.Impl.BackupStore do
  alias Matryoshka.IsStorage
  alias Matryoshka.Storage

  @enforce_keys [:source_store, :target_stores]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          source_store: IsStorage.t(),
          target_stores: list(IsStorage.t())
        }

  def backup_store(source_store, target_stores)
      when is_struct(source_store) and is_list(target_stores) do
    IsStorage.is_storage!(source_store)
    Enum.each(target_stores, &IsStorage.is_storage!/1)

    %__MODULE__{
      source_store: source_store,
      target_stores: target_stores
    }
  end

  alias __MODULE__

  defimpl Storage do
    def fetch(store, ref) do
      {source_store, value} = Storage.fetch(store.source_store, ref)
      store = BackupStore.backup_store(source_store, store.target_stores)
      {store, value}
    end

    def get(store, ref) do
      {source_store, value} = Storage.get(store.source_store, ref)
      store = BackupStore.backup_store(source_store, store.target_stores)
      {store, value}
    end

    def put(store, ref, value) do
      source_store = Storage.put(store.source_store, ref, value)
      target_stores = Enum.map(
        store.target_stores,
        fn store -> Storage.put(store, ref, value) end
      )
      BackupStore.backup_store(source_store, target_stores)
    end

    def delete(store, ref) do
      source_store = Storage.delete(store.source_store, ref)
      target_stores = Enum.map(
        store.target_stores,
        fn store -> Storage.delete(store, ref) end
      )
      BackupStore.backup_store(source_store, target_stores)
    end
  end
end
