# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.HCard.HCardView do
  use Pleroma.Web, :view

  alias Pleroma.FlakeId
  alias Pleroma.User
  alias Pleroma.Web.Salmon

  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag

  def pod_location do
    Pleroma.Web.Endpoint.url() <> "/"
  end

  defp flake_to_guid(<<0::integer-size(64), id::integer-size(64)>>) do
    :crypto.hash(:md5, (Pleroma.Web.Endpoint.url() <> Kernel.to_string(id)))
    |> Base.encode16(case: :lower)
  end

  defp flake_to_guid(id), do: Base.encode16(id, case: :lower)

  def to_guid(%User{} = user), do: FlakeId.from_string(user.id) |> flake_to_guid()

  def public_key(%User{} = user) do
    {:ok, _, public_key} = Salmon.keys_from_pem(user.info.keys)
    public_key = :public_key.pem_entry_encode(:SubjectPublicKeyInfo, public_key)
    :public_key.pem_encode([public_key])
  end
end
