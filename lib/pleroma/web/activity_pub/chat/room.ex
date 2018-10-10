defmodule Pleroma.Web.ActivityPub.Chat.Room do
  alias Pleroma.Web.ActivityPub.Actor
  alias Pleroma.Object

  def build(name) do
    base_url = Pleroma.Web.Endpoint.url()
    base = "#{base_url}/chat/rooms/#{name}"
    with {:ok, actor} <- Actor.build(base) do
      room = actor
      |> Map.put("name", name)
      |> Map.put("members", [])
      |> Map.put("type", "ChatRoom")

      {:ok, room}
    end
  end

  def create(name) do
    with {:ok, room} <- build(name) do
      Object.create(room)
    end
  end

  def join(user, room_id) do
    with object <- Object.get_cached_by_ap_id(room_id),
         false <- object == nil,
         members <- object.data["members"] || [],
         members <- Enum.uniq(members ++ [user]),
         data <- Map.put(object.data, "members", members),
         cng <- Object.change(object, %{data: data}) do
      Pleroma.Repo.update(cng)
    end
  end

  def leave(user, room_id) do
    with object <- Object.get_cached_by_ap_id(room_id),
         false <- object == nil,
         members <- object.data["members"] || [],
         members <- List.delete(members, user),
         data <- Map.put(object.data, "members", members),
         cng <- Object.change(object, %{data: data}) do
      Pleroma.Repo.update(cng)
    end
  end
end
