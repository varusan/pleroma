defmodule Pleroma.Web.OStatus.JoinHandler do
  alias Pleroma.Web.{XML, OStatus}
  alias Pleroma.Web.ActivityPub.ActivityPub
  alias Pleroma.User

  def handle(entry, doc) do
    with {:ok, actor} <- OStatus.find_make_or_update_user(doc),
         id when not is_nil(id) <- XML.string_from_xpath("/entry/id", entry),
         joined_uri when not is_nil(joined_uri) <- XML.string_from_xpath("/entry/activity:object/id", entry),
         {:ok, %User{group: true} = joined} <- OStatus.find_or_make_user(joined_uri),
         {:ok, activity} <- ActivityPub.join(actor, joined, id, false) do
      User.follow(actor, joined)
      {:ok, activity}
    end
  end
end
