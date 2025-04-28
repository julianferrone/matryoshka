defmodule StorageCombinators.Impl.PassThrough do
  import StorageCombinators.Assert, only: [is_storage!: 1]

  @enforce_keys [:inner]
  defstruct [:inner]

  @typedoc """
  A struct that implements the StorageCombinators.Storage protocol.
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

  defimpl StorageCombinators.Storage do
    def fetch(%PassThrough{inner: inner}, ref) do
      {new_inner, value} = StorageCombinators.Storage.fetch(inner, ref)
      store = PassThrough.pass_through(new_inner)
      {store, value}
    end

    def get(%PassThrough{inner: inner}, ref) do
      {new_inner, value} = StorageCombinators.Storage.get(inner, ref)
      store = PassThrough.pass_through(new_inner)
      {store, value}
    end

    def put(%PassThrough{inner: inner}, ref, value) do
      new_inner = StorageCombinators.Storage.put(inner, ref, value)
      PassThrough.pass_through(new_inner)
    end

    def delete(%PassThrough{inner: inner}, ref) do
      new_inner = StorageCombinators.Storage.delete(inner, ref)
      PassThrough.pass_through(new_inner)
    end
  end
end
