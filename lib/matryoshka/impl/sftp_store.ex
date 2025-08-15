defmodule Matryoshka.Impl.SftpStore do
  @enforce_keys [:pid, :connection]
  defstruct [:pid, :connection]

  @type t :: %__MODULE__{
          pid: pid(),
          connection: :ssh.connection_ref()
        }

  def sftp_store(host, port, username, password) do
    username = String.to_charlist(username)
    password = String.to_charlist(password)

    :ssh.start()

    {:ok, pid, connection} =
      :ssh_sftp.start_channel(
        host,
        port,
        [
          silently_accept_hosts: true,
          user: username,
          password: password
        ]
      )

    %__MODULE__{pid: pid, connection: connection}
  end

  defimpl Matryoshka.Storage do
    def fetch(store, ref) do
      value =
        case :ssh_sftp.read_file(
               store.pid,
               String.to_charlist(ref)
             ) do
          {:ok, bin} -> {:ok, :erlang.binary_to_term(bin)}
          {:error, :no_such_file} -> {:error, {:no_ref, ref}}
          {:error, other} -> {:error, other}
        end

      {store, value}
    end

    def get(store, ref) do
      ref = String.to_charlist(ref)

      value =
        case :ssh_sftp.read_file(store.pid, ref) do
          {:ok, bin} -> :erlang.binary_to_term(bin)
          {:error, _reason} -> nil
        end

      {store, value}
    end

    def put(store, ref, value) do
      :ssh_sftp.write_file(
        store.pid,
        String.to_charlist(ref),
        :erlang.term_to_binary(value)
      )

      store
    end

    def delete(store, ref) do
      :ssh_sftp.delete(
        store.pid,
        String.to_charlist(ref)
      )

      store
    end
  end
end
