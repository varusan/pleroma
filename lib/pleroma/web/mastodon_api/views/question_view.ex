# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.MastodonAPI.QuestionView do
  use Pleroma.Web, :view

  alias Pleroma.Activity
  alias Pleroma.Question
  alias Pleroma.User

  def render("show.json", %{question_id: question_id, user: %User{} = user})
      when is_binary(question_id) do
    render("show.json", %{activity: Activity.get_by_ap_id(question_id), user: user})
  end

  def render("show.json", %{activity: nil}), do: %{}

  def render(
        "show.json",
        %{
          activity: %{
            id: id,
            data: %{
              "object" =>
                %{
                  "replies" => %{
                    "items" => replies,
                    "totalItems" => total_votes
                  },
                  "endTime" => expires_in
                } = object
            }
          },
          user: %User{} = user
        }
      ) do
    do_render("show.json", %{
      id: id,
      expires_in: expires_in,
      multiple: Map.has_key?(object, "anyOf"),
      poll_options: Question.options_to_array(object["anyOf"] || object["oneOf"]),
      replies: replies,
      total_votes: total_votes,
      user_id: user.ap_id,
      published: object["published"]
    })
  end

  defp do_render("show.json", %{expires_in: expires_in} = opts) when is_binary(expires_in) do
    do_render("show.json", %{opts | expires_in: String.to_integer(expires_in)})
  end

  defp do_render("show.json", opts) do
    %{
      id: opts[:id],
      expired: poll_expired(opts[:published], opts[:expires_in]),
      multiple: opts[:multiple],
      voted: Enum.any?(opts[:replies], &(&1["attributedTo"] == opts[:user_id])),
      votes_count: opts[:total_votes],
      options: build_options(opts[:replies], opts[:poll_options]),
      emojis: []
    }
  end

  defp build_options(all_votes, options) do
    options
    |> Enum.map(fn option ->
      %{
        title: option,
        votes_count: count_votes(all_votes, option)
      }
    end)
  end

  defp count_votes(items, option) do
    Enum.reduce(items, 0, fn item, acc -> if item["name"] == option, do: acc + 1, else: acc end)
  end

  defp poll_expired(poll_created, expires_in) do
    {:ok, published_date, _} = DateTime.from_iso8601(poll_created)
    {:ok, expired_date} = Calendar.DateTime.add(published_date, expires_in)

    DateTime.compare(expired_date, DateTime.utc_now()) == :lt
  end
end
