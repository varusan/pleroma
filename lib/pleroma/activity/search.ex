# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Activity.Search do
  alias Pleroma.Activity
  alias Pleroma.Object.Fetcher
  alias Pleroma.Repo
  alias Pleroma.User
  alias Pleroma.Web.ActivityPub.Visibility

  import Ecto.Query

  def search(user, search_query) do
    index_type = if Pleroma.Config.get([:database, :rum_enabled]), do: :rum, else: :gin

    Activity
    |> Activity.with_preloaded_object()
    |> Activity.restrict_deactivated_users()
    |> restrict_public()
    |> query_with(index_type, search_query)
    |> maybe_restrict_local(user)
    |> Repo.all()
    |> maybe_fetch(user, search_query)
  end

  defp restrict_public(q) do
    from([a, o] in q,
      where: fragment("?->>'type' = 'Create'", a.data),
      where: "https://www.w3.org/ns/activitystreams#Public" in a.recipients,
      limit: 40
    )
  end

  defp query_with(q, :gin, search_query) do
    from([a, o] in q,
      where:
        fragment(
          "to_tsvector('english', ?->>'content') @@ plainto_tsquery('english', ?)",
          o.data,
          ^search_query
        ),
      order_by: [desc: :id]
    )
  end

  defp query_with(q, :rum, search_query) do
    from([a, o] in q,
      where:
        fragment(
          "? @@ plainto_tsquery('english', ?)",
          o.fts_content,
          ^search_query
        ),
      order_by: [fragment("? <=> now()::date", o.inserted_at)]
    )
  end

  # users can search everything
  defp maybe_restrict_local(q, %User{}), do: q

  # unauthenticated users can only search local activities
  defp maybe_restrict_local(q, _) do
    if Pleroma.Config.get([:instance, :limit_unauthenticated_to_local_content], true) do
      where(q, local: true)
    else
      q
    end
  end

  defp maybe_fetch(activities, user, search_query) do
    with true <- Regex.match?(~r/https?:/, search_query),
         {:ok, object} <- Fetcher.fetch_object_from_id(search_query),
         %Activity{} = activity <- Activity.get_create_by_object_ap_id(object.data["id"]),
         true <- Visibility.visible_for_user?(activity, user) do
      activities ++ [activity]
    else
      _ -> activities
    end
  end
end
