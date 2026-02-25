defmodule ContactosApp.Repo.Migrations.CreateCallLogs do
  use Ecto.Migration

  def change do
    create table(:call_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :contact_id, references(:contacts, type: :uuid, on_delete: :delete_all), null: false
      add :direction, :text, null: false
      add :duration_seconds, :integer, null: false, default: 0
      add :notes, :text
      add :called_at, :utc_datetime_usec, null: false
    end
  end
end
