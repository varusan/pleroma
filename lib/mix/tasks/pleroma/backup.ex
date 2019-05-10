# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.Backup do
  use Mix.Task
  alias Mix.Tasks.Pleroma.Common

  @shortdoc "Manage Pleroma backups"
  @moduledoc """
  Manage Pleroma backups.

  ## Generate a new instance backup.

    mix pleroma.backup gen OUTPUT_FILE

  ## Restore an old instance backup.

    mix pleroma.backup restore FILE
  """
  def run(["gen", filename]) do
    Common.start_pleroma()

    Pleroma.Backup.make_backup(filename)
  end

  def run(["restore", filename]) do
    Common.start_pleroma()

    Pleroma.Backup.restore_backup(filename)
  end
end
