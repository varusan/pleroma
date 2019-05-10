# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Backup do
  alias Pleroma.Activity
  alias Pleroma.Config
  alias Pleroma.Object
  alias Pleroma.RepoStreamer
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
  defp dump_users(writer) do
    Logger.info("Writing user list")

    Pleroma.User.Query.build(%{})
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%User{} = u] ->
      filename =
        "users/#{u.id}.json"
        |> String.to_charlist()

      {:ok, blob} = u |> Jason.encode()

      writer |> :erl_tar.add(blob, filename, [])
    end)
    |> Stream.run()

    writer
  end

  defp dump_objects(writer) do
    Logger.info("Writing objects")

    Object.base_query()
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%Object{} = o] ->
      filename =
        "objects/#{o.id}.json"
        |> String.to_charlist()

      {:ok, blob} = o |> Jason.encode()

      writer |> :erl_tar.add(blob, filename, [])
    end)
    |> Stream.run()

    writer
  end

  defp dump_activities(writer) do
    Logger.info("Writing activities")

    Activity.base_query()
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%Activity{} = a] ->
      filename =
        "activities/#{a.id}.json"
        |> String.to_charlist()

      {:ok, blob} = a |> Jason.encode()

      writer |> :erl_tar.add(blob, filename, [])
    end)
    |> Stream.run()

    writer
  end

  defp dump_uploads(writer) do
    if Config.get([Pleroma.Upload, :uploader]) != Pleroma.Uploader.Local do
      Logger.info("Writing uploads")
    else
      Logger.info("Non-local uploader in use, not writing uploads.")
    end

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
