defprotocol StorageCombinators.Reference do
  @doc """
  Splits a Reference into the list of underlying path components.
  """
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
