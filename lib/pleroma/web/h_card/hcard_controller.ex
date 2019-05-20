# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.HCard.Controller do
  @moduledoc "Renderer module for profiles in hCard format."

  use Pleroma.Web, :controller

  alias Pleroma.User

  def profile(conn, %{"nickname" => nickname}) do
    with %User{} = user <- User.get_by_nickname(nickname) do
      conn
      |> put_view(Pleroma.Web.HCard.HCardView)
      |> render("hcard.html", %{user: user})
    else
      _e ->
        conn
        |> put_status(404)
        |> text("Not found")
    end
  end
end
