defmodule Pleroma.Web.ActivityPub.Chat.RoomTest do
  use Pleroma.DataCase
  alias Pleroma.Web.ActivityPub.Chat.Room
  alias Pleroma.Object

  test "builds a local room" do
    {:ok, room} = Room.build("chatroom")
    assert room["id"] =~ "/chat/rooms/chatroom"
    assert room["name"] == "chatroom"
    assert room["members"] == []
    assert room["inbox"]
    assert room["type"] == "ChatRoom"
  end

  test "creates a local room building it and inserting it into the object database" do
    {:ok, %Object{} = room} = Room.create("chatroom")
    assert room.data["id"] =~ "/chat/rooms/chatroom"

    # Inserting the same again will fail
    assert {:error, _} = Room.create("chatroom")
  end

  test "makes it possible to join and leave a room, adding a user to the memberships" do
    {:ok, room} = Room.create("chatroom")
    actor_id = "https://user_at_some_server.com"
    {:ok, %Object{} = room} = Room.join(actor_id, room.data["id"])

    assert room.data["members"] == [actor_id]

    {:ok, %Object{} = room} = Room.leave(actor_id, room.data["id"])

    assert room.data["members"] == []
  end
end
