defmodule Pleroma.ChatTest do
  use Pleroma.DataCase
  alias Pleroma.Chat

  import Pleroma.Factory
  import Mock

  test "makes a user join a room that doesn't exist yet" do
    user = insert(:user)
    {:ok, room} = Chat.join_room(user, "public")
    assert room.data["id"]
    assert room.data["name"] == "public"
    assert room.data["members"] == [user.ap_id]
    assert room.data["type"] == "Room"
  end

  test "makes a user join a remote room" do
    user = insert(:user)

    {:ok, _room} =
      Chat.Room.create_room(
        "public:pleroma.soykaf.com",
        "https://pleroma.soykaf.com/rooms/public"
      )

    {:ok, room} = Chat.join_room(user, "public:pleroma.soykaf.com")
    assert room.data["members"] == [user.ap_id]
  end

  test "Returns the rooms a user is in" do
    user = insert(:user)
    other_user = insert(:user)
    {:ok, room_one} = Chat.join_room(user, "public")
    {:ok, room_two} = Chat.join_room(user, "2hu")
    {:ok, room_two} = Chat.join_room(other_user, "2hu")

    {:ok, room_three} = Chat.join_room(other_user, "other")

    rooms = Chat.rooms_for_user(user)
    assert room_one in rooms
    assert room_two in rooms
    refute room_three in rooms
  end

  test "returns a room name for a given room" do
    {:ok, room} = Chat.Room.create_room("public")
    assert Chat.Room.topic_name(room) == "public"

    {:ok, room} =
      Chat.Room.create_room(
        "public:pleroma.soykaf.com",
        "https://pleroma.soykaf.com/rooms/public"
      )

    assert Chat.Room.topic_name(room) == "public:pleroma.soykaf.com"
  end

  test "it adds a chat message to an existing room" do
    {:ok, room} = Chat.Room.create_room("2hu")
    user = insert(:user)

    Chat.add_remote_message(user, room, "Why is Tenshi eating a corndog so cute?")
    assert [message] = Pleroma.Web.ChatChannel.ChatChannelState.messages(room.data["id"])
    assert message.text == "Why is Tenshi eating a corndog so cute?"
    assert message.author.acct == user.nickname
  end
end
