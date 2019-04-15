# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.ConversationTest do
  use Pleroma.DataCase
  alias Pleroma.Conversation
  alias Pleroma.Web.CommonAPI

  import Pleroma.Factory

  test "it creates a conversation for given ap_id" do
    assert {:ok, %Conversation{} = conversation} =
             Conversation.create_for_ap_id("https://some_ap_id")

    # Inserting again returns the same
    assert {:ok, conversation_two} = Conversation.create_for_ap_id("https://some_ap_id")
    assert conversation_two.id == conversation.id
  end

  test "public posts don't create conversations" do
    user = insert(:user)
    {:ok, activity} = CommonAPI.post(user, %{"status" => "Hey"})

    context = activity.data["object"]["context"]

    conversation = Conversation.get_for_ap_id(context)

    refute conversation
  end

  test "it creates or updates a conversation and participations for a given DM" do
    har = insert(:user)
    jafnhar = insert(:user, local: false)
    tridi = insert(:user)

    {:ok, activity} =
      CommonAPI.post(har, %{"status" => "Hey @#{jafnhar.nickname}", "visibility" => "direct"})

    context = activity.data["object"]["context"]

    conversation =
      Conversation.get_for_ap_id(context)
      |> Repo.preload(:participations)

    assert conversation

    assert Enum.find(conversation.participations, fn %{user_id: user_id} -> har.id == user_id end)

    assert Enum.find(conversation.participations, fn %{user_id: user_id} ->
             jafnhar.id == user_id
           end)

    {:ok, activity} =
      CommonAPI.post(jafnhar, %{
        "status" => "Hey @#{har.nickname}",
        "visibility" => "direct",
        "in_reply_to_status_id" => activity.id
      })

    context = activity.data["object"]["context"]

    conversation_two =
      Conversation.get_for_ap_id(context)
      |> Repo.preload(:participations)

    assert conversation_two.id == conversation.id

    assert Enum.find(conversation_two.participations, fn %{user_id: user_id} ->
             har.id == user_id
           end)

    assert Enum.find(conversation_two.participations, fn %{user_id: user_id} ->
             jafnhar.id == user_id
           end)

    {:ok, activity} =
      CommonAPI.post(tridi, %{
        "status" => "Hey @#{har.nickname}",
        "visibility" => "direct",
        "in_reply_to_status_id" => activity.id
      })

    context = activity.data["object"]["context"]

    conversation_three =
      Conversation.get_for_ap_id(context)
      |> Repo.preload(:participations)

    assert conversation_three.id == conversation.id

    assert Enum.find(conversation_three.participations, fn %{user_id: user_id} ->
             har.id == user_id
           end)

    assert Enum.find(conversation_three.participations, fn %{user_id: user_id} ->
             jafnhar.id == user_id
           end)

    assert Enum.find(conversation_three.participations, fn %{user_id: user_id} ->
             tridi.id == user_id
           end)
  end
end