# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Question do
  use Ecto.Schema

  alias Pleroma.Activity
  alias Pleroma.Repo

  import Ecto.Query

  def add_reply_by_id(id, choices, actor) do
    with {:ok, _activity} <- add_reply(id, choices, actor),
         {:ok, activity} <- increment_total(id, choices) do
      {:ok, activity}
    end
  end

  def get_by_object_id(id) do
    Repo.one(
      from(activity in Activity,
        where:
          fragment(
            "(?)->>'attributedTo' = ? AND (?)->>'type' = 'Question'",
            activity.data,
            ^id,
            activity.data
          )
      )
    )
  end

  defp add_reply(id, choices, actor) when is_binary(id) do
    with question <- Activity.get_by_id(id),
         true <- valid_choice_indices(question, choices),
         false <- actor_already_voted(question, actor) do
      add_reply(question, choices, actor)
    else
      _ ->
        {:noop, id}
    end
  end

  defp add_reply(question, choices, actor) when is_list(choices) do
    choices
    |> Enum.map(&String.to_integer/1)
    |> Enum.map(fn choice ->
      add_reply(question, choice_name_by_index(question, choice), actor)
    end)

    {:ok, question}
  end

  defp add_reply(%Activity{} = question, name, actor) when is_binary(name) do
    from(activity in Activity,
      where: activity.id == ^question.id
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

  defp get_options(question) do
    question.data["anyOf"] || question.data["oneOf"]
  end

  def choice_name_by_index(question, index) do
    Enum.at(get_options(question), index)
  end

  defp actor_already_voted(%{data: %{"replies" => %{"items" => []}}}, _actor), do: false

  defp actor_already_voted(%{data: %{"replies" => %{"items" => replies}}}, actor) do
    Enum.any?(replies, &(&1["attributedTo"] == actor))
  end

  defp valid_choice_indices(%{data: %{"anyOf" => options}}, choices) do
    valid_choice_indices(options, choices)
  end

  defp valid_choice_indices(%{data: %{"oneOf" => options}}, choices) do
    valid_choice_indices(options, choices)
  end

  defp valid_choice_indices(options, choices) do
    choices
    |> Enum.map(&String.to_integer/1)
    |> Enum.all?(&(length(options) > &1))
  end

  defp increment_total(id, choices) do
    count = length(choices)

    from(activity in Activity,
      where: activity.id == ^id
    )
    |> update([a],
      set: [
        data:
          fragment(
            "jsonb_set(?, '{replies,totalItems}', ((?->'replies'->>'totalItems')::int + ?)::varchar::jsonb, true)",
            a.data,
            a.data,
            ^count
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
