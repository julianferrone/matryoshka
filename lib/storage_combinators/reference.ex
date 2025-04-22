defmodule StorageCombinators.Reference do
  @enforce_keys [:scheme, :path_components]
  defstruct [:scheme, :path_components]

  def path(%StorageCombinators.Reference{scheme: scheme, path_components: path_components}) do
  end
end
