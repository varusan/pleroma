# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.MastodonAPI.QuestionView do
  use Pleroma.Web, :view

  alias Pleroma.Activity

  def render("show.json", %{question_id: question_id, user_id: user_id})
      when is_binary(question_id) do
    render("show.json", %{activity: Activity.get_by_ap_id(question_id), user_id: user_id})
  end

  def render("show.json", %{activity: nil}), do: %{}

  def render(
        "show.json",
        %{
          activity: %{data: %{"id" => id, "oneOf" => options, "replies" => replies}},
          user_id: user_id
        } = activity
      )
      when is_map(activity) do
    %{
      id: id,
      user_voted: Enum.any?(replies["items"], &(&1["attributedTo"] == user_id)),
      votes:
        options
        |> Enum.map(fn option ->
          %{
            name: option,
            count: count_votes(replies["items"], option)
          }
        end)
    }
  end

  defp count_votes(items, option) do
    Enum.reduce(items, 0, fn item, acc -> if item["name"] == option, do: acc + 1, else: acc end)
  end
end
