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
  end

  test "creates a local room building it and inserting it into the object database" do
    {:ok, %Object{} = room} = Room.create("chatroom")
    assert room.data["id"] =~ "/chat/rooms/chatroom"

    # Inserting the same again will fail
    assert {:error, _} = Room.create("chatroom")
  end
end
