defmodule Pleroma.Web.ActivityPub.Chat.RoomTest do
  use Pleroma.DataCase
  alias Pleroma.Web.ActivityPub.Chat.Room

  test "builds a local room" do
    {:ok, room} = Room.build("chatroom")
    assert room["id"] =~ "/chat/rooms/chatroom"
    assert room["name"] == "chatroom"
    assert room["members"] == []
    assert room["inbox"]
  end
end
