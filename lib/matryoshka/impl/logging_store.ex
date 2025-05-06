defmodule Matryoshka.Impl.LoggingStore do
  alias Matryoshka.IsStorage
  alias Matryoshka.Storage

  @enforce_keys [:inner]
  defstruct [:inner]

  @typedoc """
  A struct that implements the Matryoshka.Storage protocol.
  """
  require Logger

  @type t :: %__MODULE__{
          inner: IsStorage.t()
        }

  def logging_store(storage) when is_struct(storage) do
    IsStorage.is_storage!(storage)
    %__MODULE__{inner: storage}
  end

  alias __MODULE__

  defimpl Storage do
    def fetch(store, ref) do
      {inner, value} = Storage.fetch(store.inner, ref)
      Logger.info(request: "FETCH", ref: ref, value: value)
      store = LoggingStore.logging_store(inner)
      {store, value}
    end

    def get(store, ref) do
      {inner, value} = Storage.get(store.inner, ref)
      Logger.info(request: "GET", ref: ref, value: value)
      store = LoggingStore.logging_store(inner)
      {store, value}
    end

    def put(store, ref, value) do
      Logger.info(request: "PUT", ref: ref, value: value)
      inner = Storage.put(store.inner, ref, value)
      LoggingStore.logging_store(inner)
    end

    def delete(store, ref) do
      Logger.info(request: "DELETE", ref: ref)
      inner = Storage.delete(store.inner, ref)
      LoggingStore.logging_store(inner)
    end
  end
end
