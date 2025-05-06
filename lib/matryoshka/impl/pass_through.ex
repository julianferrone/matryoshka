defmodule Matryoshka.Impl.PassThrough do
  alias Matryoshka.IsStorage

  @enforce_keys [:inner]
  defstruct [:inner]

  @type t :: %__MODULE__{
          inner: IsStorage.t()
        }

  def pass_through(storage) when is_struct(storage) do
    IsStorage.is_storage!(storage)
    %__MODULE__{inner: storage}
  end

  alias __MODULE__

  defimpl Matryoshka.Storage do
    def fetch(store, ref) do
      {new_inner, value} = Matryoshka.Storage.fetch(store.inner, ref)
      store = PassThrough.pass_through(new_inner)
      {store, value}
    end

    def get(store, ref) do
      {new_inner, value} = Matryoshka.Storage.get(store.inner, ref)
      store = PassThrough.pass_through(new_inner)
      {store, value}
    end

    def put(store, ref, value) do
      new_inner = Matryoshka.Storage.put(store.inner, ref, value)
      PassThrough.pass_through(new_inner)
    end

    def delete(store, ref) do
      new_inner = Matryoshka.Storage.delete(store.inner, ref)
      PassThrough.pass_through(new_inner)
    end
  end
end
