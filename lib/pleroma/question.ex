# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Question do
  use Ecto.Schema

  alias Pleroma.Activity
  alias Pleroma.Repo

  import Ecto.Query

  def add_reply_by_ap_id(ap_id, name, actor) do
    with {:ok, _activity} <- add_reply(ap_id, name, actor),
         {:ok, activity} <- increment_total(ap_id) do
      {:ok, activity}
    end
  end

  def get_by_object_id(ap_id) do
    Repo.one(
      from(activity in Activity,
        where:
          fragment(
            "(?)->>'attributedTo' = ? AND (?)->>'type' = 'Question'",
            activity.data,
            ^ap_id,
            activity.data
          )
      )
    )
  end

  defp add_reply(ap_id, name, actor) when is_binary(ap_id) do
    with question <- Activity.get_by_ap_id(ap_id),
         true <- valid_option(question, name),
         false <- actor_already_voted(question, actor) do
      add_reply(question, name, actor)
    else
      _ ->
        {:noop, ap_id}
    end
  end

  defp add_reply(%Activity{} = question, name, actor) do
    from(
      a in Activity,
      where: fragment("(?)->>'id' = ?", a.data, ^to_string(question.data["id"]))
    )
    |> update([a],
      set: [
        data:
          fragment(
            "jsonb_set(?, '{replies,items}', (?->'replies'->'items') || ?, true)",
            a.data,
            a.data,
            ^%{"name" => name, "attributedTo" => actor}
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

  defp actor_already_voted(%{data: %{"replies" => %{"items" => []}}}, _actor), do: false

  defp actor_already_voted(%{data: %{"replies" => %{"items" => replies}}}, actor) do
    Enum.any?(replies, &(&1["attributedTo"] == actor))
  end

  defp valid_option(%{data: %{"oneOf" => options}}, option) do
    Enum.member?(options, option)
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

  def is_question(activity) when is_nil(activity), do: false
  def is_question(%{data: %{"type" => type}}), do: type == "Question"
end
