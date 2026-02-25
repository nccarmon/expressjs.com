defmodule ContactosApp.CRM.MessageLog do
  use Ash.Resource, domain: ContactosApp.CRM, data_layer: AshPostgres.DataLayer

  postgres do
    table "message_logs"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy]
    create :create, accept: [:contact_id, :channel, :subject, :body, :status]
  end

  attributes do
    uuid_primary_key :id
    attribute :channel, :atom, constraints: [one_of: [:email, :whatsapp]], allow_nil?: false
    attribute :subject, :string
    attribute :body, :string, allow_nil?: false
    attribute :status, :atom, default: :queued
    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :contact, ContactosApp.CRM.Contact, allow_nil?: false, attribute_type: :uuid
  end
end
