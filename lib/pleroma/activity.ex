# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Activity do
  use Ecto.Schema

  alias Pleroma.Repo
  alias Pleroma.Activity
  alias Pleroma.Notification

  import Ecto.Query

  @type t :: %__MODULE__{}
  @primary_key {:id, Pleroma.FlakeId, autogenerate: true}

  schema "activities" do
    field(:data, :map)
    field(:local, :boolean, default: true)
    field(:actor, :string)
    field(:recipients, {:array, :string})
    has_many(:notifications, Notification, on_delete: :delete_all)

    timestamps()
  end

  def get_by_ap_id(ap_id) do
    Repo.one(
      from(
        activity in Activity,
        where: fragment("(?)->>'id' = ?", activity.data, ^to_string(ap_id))
      )
    )
  end

  def get_by_id(id) do
    Repo.get(Activity, id)
  end

  def by_object_ap_id(ap_id) do
    from(
      activity in Activity,
      where:
        fragment(
          "coalesce((?)->'object'->>'id', (?)->>'object') = ?",
          activity.data,
          activity.data,
          ^to_string(ap_id)
        )
    )
  end

  def create_by_object_ap_id(ap_ids) when is_list(ap_ids) do
    from(
      activity in Activity,
      where:
        fragment(
          "coalesce((?)->'object'->>'id', (?)->>'object') = ANY(?)",
          activity.data,
          activity.data,
          ^ap_ids
        ),
      where: fragment("(?)->>'type' = 'Create'", activity.data)
    )
  end

  def create_by_object_ap_id(ap_id) do
    from(
      activity in Activity,
      where:
        fragment(
          "coalesce((?)->'object'->>'id', (?)->>'object') = ?",
          activity.data,
          activity.data,
          ^to_string(ap_id)
        ),
      where: fragment("(?)->>'type' = 'Create'", activity.data)
    )
  end

  def get_all_create_by_object_ap_id(ap_id) do
    Repo.all(create_by_object_ap_id(ap_id))
  end

  def get_create_by_object_ap_id(ap_id) when is_binary(ap_id) do
    create_by_object_ap_id(ap_id)
    |> Repo.one()
  end

  def get_create_by_object_ap_id(_), do: nil

  def normalize(obj) when is_map(obj), do: Activity.get_by_ap_id(obj["id"])
  def normalize(ap_id) when is_binary(ap_id), do: Activity.get_by_ap_id(ap_id)
  def normalize(_), do: nil

  def get_in_reply_to_activity(%Activity{data: %{"object" => %{"inReplyTo" => ap_id}}}) do
    get_create_by_object_ap_id(ap_id)
  end

  def get_in_reply_to_activity(_), do: nil
end
