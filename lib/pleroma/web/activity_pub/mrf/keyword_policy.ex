# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.KeywordPolicy do
  @behaviour Pleroma.Web.ActivityPub.MRF

  defp string_matches?(string, pattern) when is_binary(pattern) do
    String.contains?(string, pattern)
  end

  defp string_matches?(string, pattern) do
    String.match?(string, pattern)
  end

  defp check_reject(%{"object" => %{"content" => content, "summary" => summary}} = message) do
    if Enum.any?(Pleroma.Config.get([:mrf_keyword, :reject]), fn pattern ->
         string_matches?(content, pattern) or string_matches?(summary, pattern)
       end) do
      {:reject, nil}
    else
      {:ok, message}
    end
  end

  defp check_ftl_removal(
         %{"to" => to, "object" => %{"content" => content, "summary" => summary}} = message
       ) do
    if "https://www.w3.org/ns/activitystreams#Public" in to and
         Enum.any?(Pleroma.Config.get([:mrf_keyword, :federated_timeline_removal]), fn pattern ->
           string_matches?(content, pattern) or string_matches?(summary, pattern)
         end) do
      to = List.delete(to, "https://www.w3.org/ns/activitystreams#Public")
      cc = ["https://www.w3.org/ns/activitystreams#Public" | message["cc"] || []]

      message =
        message
        |> Map.put("to", to)
        |> Map.put("cc", cc)

      {:ok, message}
    else
      {:ok, message}
    end
  end

  defp check_replace(%{"object" => %{"content" => content, "summary" => summary}} = message) do
    {content, summary} =
      Enum.reduce(Pleroma.Config.get([:mrf_keyword, :replace]), {content, summary}, fn {pattern,
                                                                                        replacement},
                                                                                       {content_acc,
                                                                                        summary_acc} ->
        {String.replace(content_acc, pattern, replacement),
         String.replace(summary_acc, pattern, replacement)}
      end)

    {:ok,
     message
     |> put_in(["object", "content"], content)
     |> put_in(["object", "summary"], summary)}
  end

  def save_keyword_policy(%{"federated_timeline_removal" => ftr,
                            "reject" => reject,
                            "replace" => replace}) do
    with true <- Enum.all?(ftr, &String.valid?(&1)),
         true <- Enum.all?(reject, &String.valid?(&1)),
         true <- Enum.all?(Map.keys(replace), &String.valid?(&1)),
         true <- Enum.all?(Map.values(replace), &String.valid?(&1)) do
        Pleroma.Config.put(:mrf_keyword, %{federated_timeline_removal: ftr,
                                           reject: reject,
                                           replace: replace
                                          })
          :ok
    else
      false -> {:error, "All elements must be valid strings"}
    end
  end

  def list_keyword_policy(), do: Pleroma.Config.get(:mrf_keyword)

  def nodeinfo_keyword_policy() do
    Pleroma.Config.get(:mrf_keyword, [])
      |> Enum.map(fn {key, value} ->
        {key,
          Enum.map(value, fn
            {pattern, replacement} ->
              %{
                "pattern" =>
                  if not is_binary(pattern) do
                    inspect(pattern)
                  else
                    pattern
                  end,
                "replacement" => replacement
              }

          pattern ->
            if not is_binary(pattern) do
              inspect(pattern)
            else
              pattern
            end
          end)}
      end)
      |> Enum.into(%{})
  end

  @impl true
  def filter(%{"object" => %{"content" => nil}} = message) do
    {:ok, message}
  end

  @impl true
  def filter(%{"type" => "Create", "object" => %{"content" => _content}} = message) do
    with {:ok, message} <- check_reject(message),
         {:ok, message} <- check_ftl_removal(message),
         {:ok, message} <- check_replace(message) do
      {:ok, message}
    else
      _e ->
        {:reject, nil}
    end
  end

  @impl true
  def filter(message), do: {:ok, message}
end
