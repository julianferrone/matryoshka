defmodule StorageCombinators.Reference do
  @enforce_keys [:scheme, :path_components]
  defstruct [:scheme, :path_components]

  @doc """
  Creates a Reference.
  """
  def reference(scheme, path) do
    path_components = String.split(path, "/")
    %StorageCombinators.Reference{scheme: scheme, path_components: path_components}
  end

  @doc """
  Returns the full path of the URI as a string.
  """
  def path(%StorageCombinators.Reference{scheme: scheme, path_components: path_components}) do
    path = Enum.join(path_components, "/")
    "#{scheme}://#{path}"
  end
end
