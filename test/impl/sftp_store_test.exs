defmodule MatryoshkaTest.SftpStoreTest do
  alias Matryoshka.Impl.SftpStore
  alias Matryoshka.Storage

  use ExUnit.Case, async: true
  doctest SftpStore

  @moduletag :tmp_dir

  @port 22

  @user "user"
  @password "password"

  setup do
    # Generate ephemeral RSA key for host
    rsa_key = :public_key.generate_key({:rsa, 2048, 65_537})

    # Set up SFTP server options
    {:ok, cwd} = File.cwd()

    system_dir =
      to_charlist(
        Path.join([
          cwd,
          "test",
          "ssh"
        ])
      )

    user = String.to_charlist(@user)
    password = String.to_charlist(@password)

    options = [
      # silently_accept_hosts: true,
      system_dir: system_dir,
      user_passwords: [{user, password}]
    ]

    # Start SFTP server
    :ssh.start()
    {:ok, server_ref} = :ssh.daemon(:loopback, @port, options)

    # Start SftpStore (SFTP Client)
    sftp_store = SftpStore.sftp_store(:loopback, @user, @password)

    # Close SFTP server when test is done
    on_exit(fn ->
      :ssh.stop_daemon(server_ref)
    end)

    {:ok, store: sftp_store}
  end

  test "Get on empty SftpStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.get(store, "item")

    # Assert
    assert value == nil
  end

  test "Get on empty SftpStore doesn't change SftpStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.get(store, "item")

    # Assert
    assert store == new_store
  end

  test "Fetch on empty SftpStore returns nil", %{store: store} do
    # Act
    {_new_store, value} = Storage.fetch(store, "item")

    # Assert
    assert value == {:error, {:no_ref, "item"}}
  end

  test "Fetch on empty SftpStore doesn't change SftpStore", %{store: store} do
    # Act
    {new_store, _value} = Storage.fetch(store, "item")

    # Assert
    assert store == new_store
  end

  test "Putting an item into a SftpStore then getting it returns the same value", %{store: store} do
    # Act
    store = Storage.put(store, "item", :item)
    {_store, value} = Storage.get(store, "item")

    assert :item == value
  end

  test "Deleting on an empty SftpStore doesn't change the SftpStore", %{store: store} do
    # Act
    new_store = Storage.delete(store, "item")

    # Assert
    assert store == new_store
  end

  test "Adding an item to an empty SftpStore, then deleting it immediately, returns the empty SftpStore",
       %{store: store} do
    # Act
    store_one = Storage.put(store, "item", :item)
    store_two = Storage.delete(store_one, "item")

    # Assert
    assert store == store_two
  end
end
