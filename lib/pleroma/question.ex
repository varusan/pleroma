# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Question do
  use Ecto.Schema

  alias Pleroma.Activity
  alias Pleroma.Repo

  import Ecto.Query

  def add_reply_by_ap_id(ap_id, name) do
    with {:ok, _activity} <- add_reply(ap_id, name),
         {:ok, activity} <- increment_total(ap_id) do
      {:ok, activity}
    end
  end

  defp add_reply(ap_id, name) do
    from(
      a in Activity,
      where: fragment("(?)->>'id' = ?", a.data, ^to_string(ap_id))
    )
    |> update([a],
      set: [
        data:
          fragment(
            "jsonb_set(?, '{replies,items}', (?->'replies'->'items') || ?, true)",
            a.data,
            a.data,
            ^%{"name" => name}
          )
      ]
    )
    |> select([u], u)
    |> Repo.update_all([])
    |> case do
      {1, [activity]} -> {:ok, activity}
      _ -> :error
    end
  end

  defp increment_total(ap_id) do
    from(
      a in Activity,
      where: fragment("(?)->>'id' = ?", a.data, ^to_string(ap_id))
    )
    |> update([a],
      set: [
        data:
          fragment(
            "jsonb_set(?, '{replies,totalItems}', ((?->'replies'->>'totalItems')::int + 1)::varchar::jsonb, true)",
            a.data,
            a.data
          )
      ]
    )
    |> select([u], u)
    |> Repo.update_all([])
    |> case do
      {1, [activity]} -> {:ok, activity}
      _ -> :error
    end
  end

  # (?->>'note_count')::int - 1)::varchar::jsonb

  def is_question(activity) when is_nil(activity), do: false
  def is_question(%{data: %{"type" => type}}), do: type == "Question"
end
