defprotocol StorageCombinators.Storage do
  alias StorageCombinators.Reference

  @type store :: any
  @type value :: any

  @spec fetch(store(), Reference) :: {store(), :error | {:ok, value()}}
  def fetch(store, ref)

  @spec get(store(), Reference) :: {store(), value()}
  def get(store, ref)

  @spec put(store(), Reference, value()) :: store()
  def put(store, ref, value)

  @spec delete(store(), Reference) :: store()
  def delete(store, ref)
end
