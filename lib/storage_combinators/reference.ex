defprotocol StorageCombinators.Reference do
  @doc """
  Splits a Reference into the list of underlying path components.
  """
  def path_components(reference)
end

defimpl StorageCombinators.Reference, for: String do
  def path_components(reference) do
    String.split(reference, "/")
  end
end

defimpl StorageCombinators.Reference, for: Atom do
  def path_components(reference) do
    [Atom.to_string(reference)]
  end
end
