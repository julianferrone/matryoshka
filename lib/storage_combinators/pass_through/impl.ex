defmodule StorageCombinators.PassThrough.Impl do
  @enforce_keys [:inner]
  defstruct [:inner]

  @typedoc """
  A struct that implements the StorageCombinators.Storage protocol.
  """
  @type impl_storage :: any()

  @type t :: %__MODULE__{
    inner: impl_storage
  }

  def pass_through(storage) do
    %__MODULE__{inner: storage}
  end

  defimpl StorageCombinators.Storage do
    def get(%Impl{inner: inner}, ref) do
      StorageCombinators.Storage.get(inner, ref)
    end

    def put(%Impl{inner: inner}, ref, value) do
      inner = StorageCombinators.Storage.put(inner, ref, value)
      Impl.pass_through(inner)
    end

    def delete(%Impl{inner: inner}, ref) do
      inner = StorageCombinators.Storage.delete(inner, ref)
      Impl.pass_through(inner)
    end
end
