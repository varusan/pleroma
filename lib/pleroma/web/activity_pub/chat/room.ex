defmodule Pleroma.Web.ActivityPub.Chat.Room do
  alias Pleroma.Web.ActivityPub.Actor
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
end
