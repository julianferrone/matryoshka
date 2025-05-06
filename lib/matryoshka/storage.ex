defprotocol Matryoshka.Storage do
  alias Matryoshka.Reference

  @typedoc """
  A type that implements the Matryoshka.Storage protocol.
  """
  @type store :: any

  @type value :: any

  @doc """
  Fetches the value for a specific `ref` in `store`.

  If `store` contains the given `ref` then its value is returned in the shape
  of `{:ok, value}`.
  If `store` doesn't contain `ref`, then the reason why is returned in the shape
  of `{:error, reason}`.
  """
  @spec fetch(store(), Reference.t()) ::
          {store(), {:error, value()} | {:ok, value()}}
  def fetch(store, ref)

  @doc """
  Gets the value for a specific `ref` in `store`.

  If `store` contains the given `ref` then its value `value` is returned.
  If `store` doesn't contain `ref`, `nil` is returned.
  """
  @spec get(store(), Reference.t()) :: {store(), value()}
  def get(store, ref)

  @doc """
  Puts the given `value` under `ref` in `store`.
  """
  @spec put(store(), Reference.t(), value()) :: store()
  def put(store, ref, value)

  @doc """
  Deletes the entry in `store` for a specific `ref`.

  If the `ref` does not exist, returns `store` unchanged.
  """
  @spec delete(store(), Reference.t()) :: store()
  def delete(store, ref)
end
