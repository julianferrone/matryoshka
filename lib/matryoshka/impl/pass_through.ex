defmodule Matryoshka.Impl.PassThrough do
  import Matryoshka.Assert, only: [is_storage!: 1]

  @enforce_keys [:inner]
  defstruct [:inner]

  @typedoc """
  A struct that implements the Matryoshka.Storage protocol.
  """
  @type impl_storage :: any()

  @type t :: %__MODULE__{
          inner: impl_storage
        }

  def pass_through(storage) when is_struct(storage) do
    is_storage!(storage)
    %__MODULE__{inner: storage}
  end

  alias __MODULE__

  defimpl Matryoshka.Storage do
    def fetch(%PassThrough{inner: inner}, ref) do
      {new_inner, value} = Matryoshka.Storage.fetch(inner, ref)
      store = PassThrough.pass_through(new_inner)
      {store, value}
    end

    def get(%PassThrough{inner: inner}, ref) do
      {new_inner, value} = Matryoshka.Storage.get(inner, ref)
      store = PassThrough.pass_through(new_inner)
      {store, value}
    end

    def put(%PassThrough{inner: inner}, ref, value) do
      new_inner = Matryoshka.Storage.put(inner, ref, value)
      PassThrough.pass_through(new_inner)
    end

    def delete(%PassThrough{inner: inner}, ref) do
      new_inner = Matryoshka.Storage.delete(inner, ref)
      PassThrough.pass_through(new_inner)
    end
  end
end
