# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Backup do
  alias Pleroma.Activity
  alias Pleroma.Object
  alias Pleroma.Repo
  alias Pleroma.User

  require Logger

  @moduledoc """
  Tools for restoring Pleroma from a backup or making a backup.

  Backup files consist of tar archives using the `erl_tar` module.  They consist
  of:

   - users
   - activities
   - objects
   - uploads
  """
  def write_one_user(writer, %User{} = user) do
    Logger.debug("Writing user #{inspect(user.nickname)}")

    filename =
      "users/#{user.id}.json"
      |> String.to_charlist()

    {:ok, blob} = user |> Jason.encode()

    writer |> :erl_tar.add(blob, filename, [])

    writer
  end

  defp dump_users(writer) do
    Logger.info("Writing user list")

    user_stream =
      Pleroma.User.Query.build(%{})
      |> Repo.stream()

    Repo.transaction(
      fn ->
        Enum.each(user_stream, fn u -> write_one_user(writer, u) end)
      end,
      timeout: :infinity
    )

    writer
  end

  defp write_one_object(writer, %Object{} = object) do
    Logger.debug("Writing object #{object.id}")

    filename =
      "objects/#{object.id}.json"
      |> String.to_charlist()

    {:ok, blob} = object |> Jason.encode()

    writer |> :erl_tar.add(blob, filename, [])

    writer
  end

  defp dump_objects(writer) do
    Logger.info("Writing objects")

    object_stream =
      Object.base_query()
      |> Repo.stream()

    Repo.transaction(
      fn ->
        Enum.each(object_stream, fn o -> write_one_object(writer, o) end)
      end,
      timeout: :infinity
    )

    writer
  end

  defp write_one_activity(writer, %Activity{} = activity) do
    Logger.debug("Writing activity #{activity.id}")

    filename =
      "activities/#{activity.id}.json"
      |> String.to_charlist()

    {:ok, blob} = activity |> Jason.encode()

    writer |> :erl_tar.add(blob, filename, [])

    writer
  end

  defp dump_activities(writer) do
    Logger.info("Writing activities")

    activity_stream =
      Activity.base_query()
      |> Repo.stream()

    Repo.transaction(
      fn ->
        Enum.each(activity_stream, fn a -> write_one_activity(writer, a) end)
      end,
      timeout: :infinity
    )

    writer
  end

  defp dump_uploads(writer) do
    Logger.info("Writing uploads")

    writer
  end

  @doc "Makes a backup and writes it to `output_filename`."
  def make_backup(output_filename) do
    Logger.info("Writing backup to #{inspect(output_filename)}")

    {:ok, writer} = :erl_tar.open(output_filename, [:write, :compressed])

    writer
    |> dump_users()
    |> dump_objects()
    |> dump_activities()
    |> dump_uploads()
    |> :erl_tar.close()
  end

  @doc "Restores a backup from `filename`."
  def restore_backup(filename) do
    Logger.info("Restoring backup from #{inspect(filename)}")

    {:ok, reader} = :erl_tar.open(filename, [:read, :compressed])

    reader |> :erl_tar.close()
  end
end
