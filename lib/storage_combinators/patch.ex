defprotocol StorageCombinators.Patch do
  @doc """
  Patches the first item with the second item.
  """
  @spec patch(t(), t()) :: t()
  def patch(first, second)
end

defimpl StorageCombinators.Patch, for: List do
  def patch(first, second), do: first ++ second
end

defimpl StorageCombinators.Patch, for: Map do
  def patch(first, second), do: Map.merge(first, second)
end
