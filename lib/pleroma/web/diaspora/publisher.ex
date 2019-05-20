# Pleroma: A lightweight social networking server
# Copyright _ 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Diaspora.Publisher do
  alias Pleroma.Activity
  alias Pleroma.User

  def publish(%User{} = _user, %Activity{} = _activity), do: :error

  def publish_one(_), do: :error

  def gather_webfinger_links(%User{} = user) do
    [
      %{
        "rel" => "http://microformats.org/profile/hcard",
        "type" => "text/html",
        "href" => user.ap_id <> "/hcard"
      },
      %{
        "rel" => "http://joindiaspora.com/seed_location",
        "type" => "text/html",
        "href" => Pleroma.Web.Endpoint.url()
      }
    ]
  end

  def gather_nodeinfo_protocol_names, do: ["diaspora"]
end
