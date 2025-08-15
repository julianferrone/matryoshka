defmodule Matryoshka.Impl.SftpStore do
  @enforcekeys [:pid, :connection]
  defstruct [:pid, :connection]

  @type t :: %__MODULE__{
          pid: pid(),
          connection: :ssh.connection_ref()
        }

  def sftp_store(host, username, password) do
    username = String.to_charlist(username)
    password = String.to_charlist(password)

    :ssh.start()
    {:ok, pid, connection} = :ssh_sftp.start_channel(
      host,
      [
        {:user, username},
        {:password, password}
      ]
    )
    %__MODULE__{pid: pid, connection: connection}
  end

  defimpl Matryoshka.Storage do
    def fetch(store, ref) do
      ref = String.to_charlist(ref)
      value = :ssh_sftp.read_file(store.pid, ref)
      {store, value}
    end

    def get(store, ref) do
      ref = String.to_charlist(ref)
      value = case :ssh_sftp.read_file(store.pid, ref) do
        {:ok, value} -> {:ok, value}
        {:error, _reason} -> :nil
      end
      {store, value}
    end

    def put(store, ref, value) do
      ref = String.to_charlist(ref)
      :ssh_sftp.write_file(store.pid, ref, value)
      store
    end

    def delete(store, ref) do
      ref = String.to_charlist(ref)
      :ssh_sftp.delete(store.pid, ref)
      store
    end
  end
end
