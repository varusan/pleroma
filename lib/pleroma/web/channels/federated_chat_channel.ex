defmodule Pleroma.Web.FederatedChatChannel do
  use Phoenix.Channel

  def join("federated_chat:room:" <> room_id, params, socket) do
    {:ok, socket}
  end

  def join("federated_chat:user:" <> user_id, params, socket) do
    if user_id == socket.assigns[:user_id] do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
end
