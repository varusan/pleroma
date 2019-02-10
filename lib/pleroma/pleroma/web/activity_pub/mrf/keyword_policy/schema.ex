# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Pleroma.Web.ActivityPub.MRF.KeywordPolicy.Schema do
  use Ecto.Schema
  import Ecto.Changeset


  schema "keyword_policies" do
    field :federated_timeline_removal, {:array, :string}
    field :reject, {:array, :string}
    field :replace, :map

    timestamps()
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:reject, :federated_timeline_removal, :replace])
    |> validate_required([:reject, :federated_timeline_removal, :replace])
  end
end
