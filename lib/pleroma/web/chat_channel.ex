defmodule Pleroma.Web.ChatChannel do
  use Phoenix.Channel
  alias Pleroma.Web.ChatChannel.ChatChannelState
  alias Pleroma.User
  alias Pleroma.Chat
  alias Pleroma.Web.ActivityPub.ActivityPub

  def join("chat:" <> room_name, _message, socket) do
    user = User.get_cached_by_nickname(socket.assigns.user_name)

    with {:ok, room} <- Chat.join_room(user, room_name) do
      send(self(), :after_room_join)

      socket =
        socket
        |> assign(:room_name, room.data["id"])

      {:ok, socket}
    else
      _e ->
        {:error, %{reason: "unknown"}}
    end
  end

  def join("user:" <> id, _message, socket) do
    user = User.get_cached_by_nickname(socket.assigns.user_name)

    if id == to_string(user.id) do
      send(self(), :after_user_join)
      {:ok, socket}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  def handle_info(:after_user_join, socket) do
    user = User.get_cached_by_nickname(socket.assigns.user_name)

    user_rooms =
      Chat.rooms_for_user(user)
      |> Enum.map(fn %{data: room} ->
        room
      end)

    push(socket, "rooms", %{rooms: user_rooms})
    {:noreply, socket}
  end

  def handle_info(:after_room_join, socket) do
    push(socket, "messages", %{messages: ChatChannelState.messages(socket.assigns.room_name)})
    {:noreply, socket}
  end

  def handle_in(
        "new_msg",
        %{"text" => text},
        %{assigns: %{user_name: user_name, room_name: room_id}} = socket
      ) do
    user = User.get_cached_by_nickname(user_name)
    {:ok, message} = Chat.add_message(user, room_id, text)

    if !String.starts_with?(room_id, Pleroma.Web.base_url()) do
      ActivityPub.chat_message(room_id, user, text)
    end

    broadcast!(socket, "new_msg", message)

    {:noreply, socket}
  end
end

defmodule Pleroma.Web.ChatChannel.ChatChannelState do
  @max_messages 20

  def start_link do
    Agent.start_link(fn -> %{max_id: 1, rooms: %{}} end, name: __MODULE__)
  end

  def add_message(message, room_name) do
    Agent.get_and_update(__MODULE__, fn state ->
      id = state[:max_id] + 1
      message = Map.put(message, "id", id)
      room = room_state(state, room_name)
      messages = [message | room[:messages]] |> Enum.take(@max_messages)

      room =
        room
        |> Map.put(:messages, messages)

      rooms =
        state.rooms
        |> Map.put(room_name, room)

      {message, %{max_id: id, rooms: rooms}}
    end)
  end

  def messages(room_name) do
    Agent.get(__MODULE__, fn state ->
      room_state(state, room_name)[:messages] |> Enum.reverse()
    end)
  end

  def room_state(state, room_name) do
    state[:rooms][room_name] || %{messages: []}
  end
end
