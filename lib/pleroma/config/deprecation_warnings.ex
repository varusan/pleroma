# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Config.DeprecationWarnings do
  require Logger

  def check_frontend_config_mechanism do
    if Pleroma.Config.get(:fe) do
      Logger.warn("""
      !!!DEPRECATION WARNING!!!
      You are using the old configuration mechanism for the frontend. Please check config.md.
      """)
    end
  end

  def check_hellthread_threshold do
    if Pleroma.Config.get([:mrf_hellthread, :threshold]) do
      Logger.warn("""
      !!!DEPRECATION WARNING!!!
      You are using the old configuration mechanism for the hellthread filter. Please check config.md.
      """)
    end
  end

  def check_and_fix_keyword_replace do
    replace = Pleroma.Config.get([:mrf_keyword, :replace])

    if is_list(replace) do
      Logger.warn("""
      !!!DEPRECATION WARNING!!!
      You are using the old configuration mechanism for KeywordPolicy's replace rule. Please check config.md.
      """)

      new_replace =
        Enum.reduce(replace, %{}, fn {key, value}, acc -> Map.put(acc, key, value) end)

      Pleroma.Config.put([:mrf_keyword, :replace], new_replace)
    end
  end

  def warn do
    check_frontend_config_mechanism()
    check_hellthread_threshold()
    check_and_fix_keyword_replace()
  end
end
