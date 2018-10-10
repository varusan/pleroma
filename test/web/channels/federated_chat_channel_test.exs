defmodule Pleroma.Web.FederatedChatChannelTest do
  use Pleroma.DataCase

  import Pleroma.Factory
  alias Pleroma.Web.FederatedChatChannel
  alias Pleroma.Web.ActivityPub.Chat.Room

  test "it allows joining a user topic for the user itself" do
    user = insert(:user)
    other_user = insert(:user)
    socket = %{assigns: %{user_id: to_string(user.id)}}
    other_socket = %{assigns: %{user_id: to_string(other_user.id)}}

    topic = "federated_chat:user:#{user.id}"
    assert {:ok, ^socket} = FederatedChatChannel.join(topic, %{}, socket)

    # Joining as another user will error out
    assert {:error, %{reason: "unauthorized"}} = FederatedChatChannel.join(topic, %{}, other_socket)
  end

  test "it allows joining an existing room" do
    {:ok, room} = Room.create("test_room")
    socket = %{test: :ok}

    topic = "federated_chat:room:#{room.data["id"]}"

    assert {:ok, ^socket} = FederatedChatChannel.join(topic, %{}, socket)
  end
end
