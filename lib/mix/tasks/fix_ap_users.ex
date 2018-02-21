defmodule Mix.Tasks.FixApUsers do
  use Mix.Task
  import Mix.Ecto
  import Ecto.Query
  alias Pleroma.{Repo, User}

  @shortdoc "Grab all ap users again"
  def run([]) do
    Mix.Task.run("app.start")

    q = from u in User,
      where: fragment("? @> ?", u.info, ^%{"ap_enabled" => true})
    users = Repo.all(q)

    Enum.each(users, fn(user) ->
      IO.puts("Fetching #{user.nickname}")
      Pleroma.Web.ActivityPub.Transmogrifier.upgrade_user_from_ap_id(user.ap_id)
    end)
  end
end
