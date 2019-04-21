# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Question do
  use Ecto.Schema

  alias Pleroma.Activity
  alias Pleroma.Config
  alias Pleroma.Repo

  import Ecto.Query

  def add_reply_by_ap_id(ap_id, choices, actor) do
    with {:ok, _activity} <- add_reply(ap_id, choices, actor),
         {:ok, activity} <- increment_total(ap_id, choices) do
      {:ok, activity}
    end
  end

  def maybe_check_limits(false, _expires, _options), do: :ok

  def maybe_check_limits(true, expires, options) when is_binary(expires) do
    maybe_check_limits(true, String.to_integer(expires), options)
  end

  def maybe_check_limits(true, expires, options) when is_integer(expires) do
    limits = Config.get([:instance, :poll_limits])
    expiration_range = limits[:min_expiration]..limits[:max_expiration]

    cond do
      length(options) > limits[:max_options] ->
        {:error, "The number of options exceed the maximum of #{limits[:max_options]}"}

      Enum.any?(options, &(String.length(&1) > limits[:max_option_chars])) ->
        {:error,
         "The number of option's characters exceed the maximum of #{limits[:max_option_chars]}"}

      !Enum.member?(expiration_range, expires) ->
        {:error,
         "`expires_in` must be in range of (#{limits[:min_expiration]}..#{limits[:max_expiration]}) seconds"}

      true ->
        :ok
    end
  end

  def options_to_array(options) do
    options |> Enum.map(& &1["name"])
  end

  defp add_reply(ap_id, choices, actor) when is_binary(ap_id) do
    with question <- Activity.get_by_ap_id(ap_id),
         true <- maybe_ensure_multipe(question, choices),
         true <- valid_choice_indices(question, choices),
         false <- actor_already_voted(question, actor) do
      add_reply(question, choices, actor)
    else
      _ ->
        {:noop, ap_id}
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

  defp add_reply(question, name, actor) when is_binary(name) do
    from(
      a in Activity,
      where: fragment("(?)->>'id' = ?", a.data, ^to_string(question.data["id"]))
    )
    |> update([a],
      set: [
        data:
          fragment(
            "jsonb_set(?, '{object,replies,items}', (?->'object'->'replies'->'items') || ?, true)",
            a.data,
            a.data,
            ^%{"type" => "Note", "name" => name, "attributedTo" => actor}
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

  def choice_name_by_index(question, index) do
    (question.data["object"]["anyOf"] || question.data["object"]["oneOf"])
    |> options_to_array()
    |> Enum.at(index)
  end

  defp maybe_ensure_multipe(_question, choices) when length(choices) == 1, do: true
  defp maybe_ensure_multipe(%{data: %{"object" => %{"oneOf" => _one_of}}}, _choices), do: false
  defp maybe_ensure_multipe(%{data: %{"object" => %{"anyOf" => _any_of}}}, _choices), do: true

  defp actor_already_voted(%{data: %{"object" => %{"replies" => %{"items" => []}}}}, _actor),
    do: false

  defp actor_already_voted(%{data: %{"object" => %{"replies" => %{"items" => replies}}}}, actor) do
    Enum.any?(replies, &(&1["attributedTo"] == actor))
  end

  defp valid_choice_indices(%{data: %{"object" => %{"anyOf" => options}}}, choices) do
    valid_choice_indices(options, choices)
  end

  defp valid_choice_indices(%{data: %{"object" => %{"oneOf" => options}}}, choices) do
    valid_choice_indices(options, choices)
  end

  defp valid_choice_indices(options, choices) do
    choices
    |> Enum.map(&String.to_integer/1)
    |> Enum.all?(&(length(options) > &1))
  end

  defp increment_total(ap_id, choices) do
    count = length(choices)

    from(a in Activity,
      where: fragment("(?)->>'id' = ?", a.data, ^to_string(ap_id))
    )
    |> update([a],
      set: [
        data:
          fragment(
            "jsonb_set(?, '{object,replies,totalItems}', ((?->'object'->'replies'->>'totalItems')::int + ?)::varchar::jsonb, true)",
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
  def is_question(%{data: %{"object" => %{"type" => type}}}), do: type == "Question"
end
