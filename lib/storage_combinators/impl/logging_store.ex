defmodule Matryoshka.Impl.LoggingStore do
  import Matryoshka.Assert, only: [is_storage!: 1]

  @enforce_keys [:inner]
  defstruct [:inner]

  @typedoc """
  A struct that implements the Matryoshka.Storage protocol.
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

  defimpl Matryoshka.Storage do
    def fetch(%LoggingStore{inner: inner} = store, ref) do
      {inner, value} = Matryoshka.Storage.fetch(inner, ref)
      Logger.info("FETCH #{inspect(ref)} => #{inspect(value)}")
      store = %{store | inner: inner}
      {store, value}
    end

    def get(%LoggingStore{inner: inner} = store, ref) do
      {inner, value} = Matryoshka.Storage.get(inner, ref)
      Logger.info("GET #{inspect(ref)} => #{inspect(value)}")
      store = %{store | inner: inner}
      {store, value}
    end

    def put(%LoggingStore{inner: inner}, ref, value) do
      Logger.info("PUT #{inspect(ref)} <= #{inspect(value)}")
      inner = Matryoshka.Storage.put(inner, ref, value)
      LoggingStore.logging_store(inner)
    end

    def delete(%LoggingStore{inner: inner}, ref) do
      Logger.info("DELETE #{inspect(ref)}")
      inner = Matryoshka.Storage.delete(inner, ref)
      LoggingStore.logging_store(inner)
    end
  end
end
