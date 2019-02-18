# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Notification do
  use Ecto.Schema

  alias Pleroma.User
  alias Pleroma.Activity
  alias Pleroma.Notification
  alias Pleroma.Repo
  alias Pleroma.Web.CommonAPI.Utils
  alias Pleroma.Web.CommonAPI

  import Ecto.Query

  schema "notifications" do
    field(:seen, :boolean, default: false)
    belongs_to(:user, User, type: Pleroma.FlakeId)
    belongs_to(:activity, Activity, type: Pleroma.FlakeId)

    timestamps()
  end

  # https://github.com/tootsuite/mastodon/blob/master/app/models/notification.rb#L19
  @mastodon_notification_types %{
    "Create" => "mention",
    "Follow" => "follow",
    "Announce" => "reblog",
    "Like" => "favourite"
  }
  @supported_activity_types Map.keys(@mastodon_notification_types)
  @activity_mastodon_types Utils.map_exchange_key_value(@mastodon_notification_types)

  def mastodon_notification_types(), do: @mastodon_notification_types
  def supported_activity_types(), do: @supported_activity_types
  def activity_mastodon_types(), do: @activity_mastodon_types

  # TODO: Make generic and unify (see activity_pub.ex)
  defp restrict_max(query, %{"max_id" => max_id}) do
    from(activity in query, where: activity.id < ^max_id)
  end

  defp restrict_max(query, _), do: query

  defp restrict_since(query, %{"since_id" => since_id}) do
    from(activity in query, where: activity.id > ^since_id)
  end

  defp restrict_since(query, _), do: query

  defp restrict_exclude_types(query, %{"exclude_types" => types}) when is_list(types) do
    from(n in query, where: fragment("not (?->>'type' = ANY(?))", n.data, ^types))
  end

  defp restrict_exclude_types(query, _), do: query

  def for_user(user, opts \\ %{}) do
    query =
      from(
        n in Notification,
        where: n.user_id == ^user.id,
        order_by: [desc: n.id],
        join: activity in assoc(n, :activity),
        preload: [activity: activity],
        limit: 20
      )

    query =
      query
      |> restrict_since(opts)
      |> restrict_max(opts)
      |> restrict_exclude_types(opts)

    Repo.all(query)
  end

  def set_read_up_to(%{id: user_id} = _user, id) do
    query =
      from(
        n in Notification,
        where: n.user_id == ^user_id,
        where: n.id <= ^id,
        update: [
          set: [seen: true]
        ]
      )

    Repo.update_all(query, [])
  end

  def get(%{id: user_id} = _user, id) do
    query =
      from(
        n in Notification,
        where: n.id == ^id,
        join: activity in assoc(n, :activity),
        preload: [activity: activity]
      )

    notification = Repo.one(query)

    case notification do
      %{user_id: ^user_id} ->
        {:ok, notification}

      _ ->
        {:error, "Cannot get notification"}
    end
  end

  def clear(user) do
    from(n in Notification, where: n.user_id == ^user.id)
    |> Repo.delete_all()
  end

  def dismiss(%{id: user_id} = _user, id) do
    notification = Repo.get(Notification, id)

    case notification do
      %{user_id: ^user_id} ->
        Repo.delete(notification)

      _ ->
        {:error, "Cannot dismiss notification"}
    end
  end

  def create_notifications(%Activity{data: %{"to" => _, "type" => type}} = activity)
      when type in @supported_activity_types do
    users = get_notified_from_activity(activity)

    notifications = Enum.map(users, fn user -> create_notification(activity, user) end)
    {:ok, notifications}
  end

  def create_notifications(_), do: {:ok, []}

  # TODO move to sql, too.
  def create_notification(%Activity{} = activity, %User{} = user) do
    unless User.blocks?(user, %{ap_id: activity.data["actor"]}) or
             CommonAPI.thread_muted?(user, activity) or user.ap_id == activity.data["actor"] or
             (activity.data["type"] == "Follow" and
                Enum.any?(Notification.for_user(user), fn notif ->
                  notif.activity.data["type"] == "Follow" and
                    notif.activity.data["actor"] == activity.data["actor"]
                end)) do
      notification = %Notification{user_id: user.id, activity: activity}
      {:ok, notification} = Repo.insert(notification)
      Pleroma.Web.Streamer.stream("user", notification)
      Pleroma.Web.Push.send(notification)
      notification
    end
  end

  def get_notified_from_activity(activity, local_only \\ true)

  def get_notified_from_activity(
        %Activity{data: %{"to" => _, "type" => type} = _data} = activity,
        local_only
      )
      when type in @supported_activity_types do
    recipients =
      []
      |> Utils.maybe_notify_to_recipients(activity)
      |> Utils.maybe_notify_mentioned_recipients(activity)
      |> Enum.uniq()

    User.get_users_from_set(recipients, local_only)
  end

  def get_notified_from_activity(_, _local_only), do: []

  @doc "Transforms Mastodon notification types to ActivityPub types"
  def masto_to_ap(masto_types) when is_list(masto_types) do
    masto_types
    |> Enum.map(fn x -> @activity_mastodon_types[x] end)
  end

  def masto_to_ap(masto_type) do
    @activity_mastodon_types[masto_type]
  end

  @doc "Transforms Activity types to Mastodon Notifications"
  def ap_to_masto(ap_types) when is_list(ap_types) do
    ap_types
    |> Enum.map(fn x -> @mastodon_notification_types[x] end)
  end

  def ap_to_masto(ap_type) do
    @mastodon_notification_types[ap_type]
  end
end
