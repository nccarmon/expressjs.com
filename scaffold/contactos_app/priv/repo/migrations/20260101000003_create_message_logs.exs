defmodule ContactosApp.Repo.Migrations.CreateMessageLogs do
  use Ecto.Migration

  def change do
    create table(:message_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :contact_id, references(:contacts, type: :uuid, on_delete: :delete_all), null: false
      add :channel, :text, null: false
      add :subject, :text
      add :body, :text, null: false
      add :status, :text, null: false, default: "queued"
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end
  end
end
