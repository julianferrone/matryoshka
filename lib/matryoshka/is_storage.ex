defmodule Matryoshka.IsStorage do
    @typedoc """
  A struct that implements the Matryoshka.Storage protocol.
  """
  @type t :: any()

  @doc """
  Assert that the provided storage struct implements the Storage protocol.
  """
  def is_storage!(storage) do
    Protocol.assert_impl!(Storage, storage.__struct__)
  end
end
