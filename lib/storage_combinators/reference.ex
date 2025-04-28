defprotocol StorageCombinators.Reference do
  @typedoc """
  A type that implements the StorageCombinators.Reference protocol.
  """
  @type impl_reference :: any

  @doc """
  Splits a Reference into the list of underlying path components.
  """
  @spec path_segments(impl_reference()) :: list(String.t())
  def path_segments(reference)
end

defimpl StorageCombinators.Reference, for: BitString do
  def path_segments(reference) do
    String.split(reference, "/")
  end
end

defimpl StorageCombinators.Reference, for: Atom do
  def path_segments(reference) do
    [Atom.to_string(reference)]
  end
end
