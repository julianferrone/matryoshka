defmodule StorageCombinators.LoggingStore do
  import StorageCombinators.StorageCombinators, only: [is_storage!: 1]

  @enforce_keys [:inner]
  defstruct [:inner]

  @typedoc """
  A struct that implements the StorageCombinators.Storage protocol.
  """
  require Logger
  @type impl_storage :: any()

  @type t :: %__MODULE__{
          inner: impl_storage
        }

  def logging_store(storage) when is_struct(storage) do
    is_storage!(storage)
    %__MODULE__{inner: storage}
  end

  alias __MODULE__

  defimpl StorageCombinators.Storage do
    def get(%LoggingStore{inner: inner}, ref) do
      value = StorageCombinators.Storage.get(inner, ref)
      Logger.info("GET #{inspect(ref)} => #{inspect(value)}")
      value
    end

    def put(%LoggingStore{inner: inner}, ref, value) do
      Logger.info("PUT #{inspect(ref)} <= #{inspect(value)}")
      inner = StorageCombinators.Storage.put(inner, ref, value)
      LoggingStore.logging_store(inner)
    end

    def delete(%LoggingStore{inner: inner}, ref) do
      Logger.info("DELETE #{inspect(ref)}")
      inner = StorageCombinators.Storage.delete(inner, ref)
      LoggingStore.logging_store(inner)
    end
  end
end
