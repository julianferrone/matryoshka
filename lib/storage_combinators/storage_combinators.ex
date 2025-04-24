defmodule StorageCombinators.StorageCombinators do
  alias StorageCombinators.Storage

  @doc """
  Assert that the provided storage struct implements the Storage protocol.
  """
  def is_storage!(storage) do
    Protocol.assert_impl!(Storage, storage.__struct__)
  end

  def get_or_nil(value) do
    case value do
      {:ok, val} -> val
      :error -> nil
    end
  end
end
