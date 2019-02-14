defmodule Pleroma.Repo.Migrations.AddPinnedObjectsToUserInfo do
  use Ecto.Migration

  def change do
    execute """
    update users set info = jsonb_set(info, '{pinned_objects}', '[]'::jsonb) where info->'pinned_objects' is null;
    """
  end
end
