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
  defp write_object_to_tar_stream(writer, filename, %{} = object) do
    {:ok, blob} = Jason.encode(object)

    write_object_to_tar_stream(writer, filename, blob)
  end

  defp write_object_to_tar_stream(writer, filename, blob) do
    filename = String.to_charlist(filename)

    :erl_tar.add(writer, blob, filename, [])
  end

  defp dump_users(writer) do
    Logger.info("Writing user list")

    Pleroma.User.Query.build(%{})
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%User{} = u] ->
      write_object_to_tar_stream(writer, "users/#{u.id}.json", u)
    end)
    |> Stream.run()

    writer
  end

  defp dump_objects(writer) do
    Logger.info("Writing objects")

    Object.base_query()
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%Object{} = o] ->
      write_object_to_tar_stream(writer, "objects/#{o.id}.json", o)
    end)
    |> Stream.run()

    writer
  end

  defp dump_activities(writer) do
    Logger.info("Writing activities")

    Activity.base_query()
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%Activity{} = a] ->
      write_object_to_tar_stream(writer, "activities/#{a.id}.json", a)
    end)
    |> Stream.run()

    writer
  end

  defp local_upload_prefix(), do: Pleroma.Web.Endpoint.url() <> "/media"
  defp is_local_upload?(path), do: String.starts_with?(path, local_upload_prefix())

  defp dump_uploads(writer) do
    import Ecto.Query

    if Config.get([Pleroma.Upload, :uploader]) != Pleroma.Uploader.Local do
      Logger.info("Writing uploads")
    else
      Logger.info("Non-local uploader in use, not writing uploads.")
    end

    uploads = Config.get([Pleroma.Uploaders.Local, :uploads], "uploads")
    prefix = local_upload_prefix()

    Object
    |> where([o], fragment("?->>'type' = 'Document' or ?->>'type' = 'Image'", o.data, o.data))
    |> RepoStreamer.chunk_stream(1)
    |> Stream.each(fn [%{data: %{"url" => [%{"href" => url}]}}] ->
      url = URI.decode(url)

      if is_local_upload?(url) do
        path = String.replace_leading(url, prefix, uploads)
        target = String.replace_leading(path, uploads, "uploads")

        with {:ok, blob} <- File.read(path) do
          write_object_to_tar_stream(writer, target, blob)
        else
          e ->
            Logger.warn("Orphaned path at #{path}, unable to read file: #{inspect(e)}")
        end
      end
    end)
    |> Stream.run()

    writer
  end

  @doc "Makes a backup and writes it to `output_filename`."
  def make_backup(output_filename) do
    Logger.info("Writing backup to #{inspect(output_filename)}")

    {:ok, writer} = :erl_tar.open(output_filename, [:write, :compressed])

    writer
    |> dump_uploads()
    |> dump_users()
    |> dump_objects()
    |> dump_activities()
    |> :erl_tar.close()
  end

  @doc "Restores a backup from `filename`."
  def restore_backup(filename) do
    Logger.info("Restoring backup from #{inspect(filename)}")

    {:ok, reader} = :erl_tar.open(filename, [:read, :compressed])

    reader |> :erl_tar.close()
  end
end
