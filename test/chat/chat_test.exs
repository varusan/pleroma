defmodule Pleroma.ChatTest do
  use Pleroma.DataCase
  alias Pleroma.Chat

  import Pleroma.Factory

  test "makes a user join a room that doesn't exist yet" do
    user = insert(:user)
    {:ok, room} = Chat.join_room(user, "public")
    assert room.data["name"] == "public"
    assert room.data["members"] == [user.ap_id]
    assert room.data["type"] == "Room"
  end

  test "Returns the rooms a user is in" do
    user = insert(:user)
    {:ok, room_one} = Chat.join_room(user, "public")
    {:ok, room_two} = Chat.join_room(user, "2hu")

    other_user = insert(:user)
    {:ok, room_three} = Chat.join_room(other_user, "other")

    rooms = Chat.rooms_for_user(user)
    assert room_one in rooms
    assert room_two in rooms
    refute room_three in rooms
  end
end
