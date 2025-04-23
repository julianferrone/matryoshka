defprotocol StorageCombinators.Storage do
  @type store :: any
  @type value :: any

  alias StorageCombinators.Reference

  @spec get(store(), Reference) :: value()
  def get(store, ref)

  @spec put(store(), Reference, value()) :: store()
  def put(store, ref, value)

  @spec delete(store(), Reference) :: store()
  def delete(store, ref)
end
