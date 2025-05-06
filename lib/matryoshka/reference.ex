defprotocol Matryoshka.Reference do
  @typedoc """
  A type that implements the Matryoshka.Reference protocol.
  """
  @type t() :: any

  @doc """
  Splits a Reference into the list of underlying path components.
  """
  @spec path_segments(t()) :: list(String.t())
  def path_segments(reference)
end

defimpl Matryoshka.Reference, for: BitString do
  def path_segments(reference) do
    String.split(reference, "/")
  end
end

defimpl Matryoshka.Reference, for: Atom do
  def path_segments(reference) do
    [Atom.to_string(reference)]
  end
end
