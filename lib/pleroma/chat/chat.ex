defmodule Pleroma.Chat do
  alias Pleroma.Chat.Room
  alias Pleroma.Repo
  alias Pleroma.Object
  alias Pleroma.Web.ChatChannel.ChatChannelState

  import Ecto.Query

  def join_room(user, room_name) do
    with {:find_room, {:ok, room}} <- {:find_room, Room.find_by_name(room_name)} do
      Room.add_member(room, user)
    end
  end

  def add_message(author, room_id, text) do
    if String.length(text) > 0 do
      author = Pleroma.Web.MastodonAPI.AccountView.render("account.json", user: author)
      {:ok, ChatChannelState.add_message(%{text: text, author: author}, room_id)}
    end
  end

  def add_remote_message(user, room, message) do
    {:ok, message} = add_message(user, room.data["id"], message)
    topic_name = Room.topic_name(room)
    Pleroma.Web.Endpoint.broadcast("chat:" <> topic_name, "new_msg", message)
  end

  def rooms_for_user(user) do
    query =
      from(
        o in Object,
        where: fragment("?->>'type' = ?", o.data, "Room"),
        where: fragment("? @> ?", o.data, ^%{members: [user.ap_id]})
      )

    Repo.all(query)
  end
end

defmodule Pleroma.Chat.Room do
  alias Pleroma.Object
  alias Pleroma.Repo

  def topic_name(room) do
    room.data["name"]
  end

  def room_id_for_name(room_name) do
    "#{Pleroma.Web.base_url()}/room/#{room_name}"
  end

  def find_by_name(room_name) do
    case Object.get_by_ap_id(room_id_for_name(room_name)) do
      %Object{} = room -> {:ok, room}
      nil -> create_room(room_name)
    end
  end

  def create_room(room_name) do
    data = %{
      "id" => room_id_for_name(room_name),
      "members" => [],
      "name" => room_name,
      "type" => "Room"
    }

    Object.create(data)
  end

  def add_member(room, user) do
    new_members =
      [user.ap_id | room.data["members"]]
      |> Enum.uniq()

    new_data =
      room.data
      |> Map.put("members", new_members)

    room
    |> Object.change(%{data: new_data})
    |> Repo.update()
  end
end
