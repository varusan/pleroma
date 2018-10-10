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

      {:ok, room}
    end
  end

  def create(name) do
    with {:ok, room} <- build(name) do
      Object.create(room)
    end
  end
end
