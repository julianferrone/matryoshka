defmodule Matryoshka.Impl.SftpStore do
  alias Matryoshka.Reference
  @enforce_keys [:pid, :connection]
  defstruct [:pid, :connection]

  @type t :: %__MODULE__{
          pid: pid(),
          connection: :ssh.connection_ref()
        }

  @doc """
  Creates a store backed by an SSH FTP (SFTP) client.

  ## Parameters

    * `host` - The hostname of the SFTP server.
    * `port` - The port of the SFTP server.
    * `username` - The username to log in to the SFTP server with.
    * `password` - The password to log in to the SFTP server with.

  Returns a `%SftpStore` struct containing the following:
    - `pid`: The PID for communicating with the SFTP server.
    - `connection`: An opaque data type representing the connection between the
        SFTP client and the SFTP server.
  """
  def sftp_store(host, port, username, password) do
    username = String.to_charlist(username)
    password = String.to_charlist(password)

    :ssh.start()

    {:ok, pid, connection} =
      :ssh_sftp.start_channel(
        host,
        port,
        silently_accept_hosts: true,
        user: username,
        password: password
      )

    %__MODULE__{pid: pid, connection: connection}
  end

  alias __MODULE__

  def parent_dirs(enumerable) do
    # This function lets us pull all the parents from a path reference, so that
    # we can make them in the underlying SFTP directory.

    # We don't want to make the last path segment as a directory, that'll be the
    # filename.
    enumerable = Enum.drop(enumerable, -1)

    # We prepend a list to the enumerable so that when we scan, we can accumulate
    # a list of lists
    [[] | enumerable]
    |> Enum.scan(&[&1 | &2])
    # Then drop the initial empty list
    |> Enum.drop(1)
    |> Enum.map(&Enum.reverse/1)
    # Then recombine them into paths with forward-slash delimiters
    |> Enum.map(&Enum.join(&1, "/"))
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
      # Make sure that parent directories exist
      segments = Reference.path_segments(ref)

      if length(segments) > 1 do
        dirs = SftpStore.parent_dirs(segments)

        Enum.each(
          dirs,
          fn dir -> :ssh_sftp.make_dir(store.pid, dir) end
        )
      end

      # Write value
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
