defmodule Pleroma.Web.ActivityPub.ActorTest do
  use Pleroma.DataCase

  alias Pleroma.Chat.Room
  alias Pleroma.Web.ActivityPub.Actor

  test "it adds keys to an object so that it can act" do
    {:ok, room} = Room.create_room("public")
    refute room.data["publicKey"]
    refute room.data["privateKey"]

    {:ok, room} = Actor.add_keys(room)

    assert room.data["privateKey"]["privateKeyPem"] =~ "BEGIN RSA PRIVATE KEY"
    assert room.data["publicKey"]["publicKeyPem"] =~ "BEGIN RSA PUBLIC KEY"
  end

  test "it adds collections and boxes" do
    {:ok, room} = Room.create_room("public")
    {:ok, room} = Actor.add_actor_properties(room)

    assert room.data["following"]
    assert room.data["followers"]
    assert room.data["inbox"]
    assert room.data["outbox"]
  end
end
