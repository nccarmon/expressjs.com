defmodule ContactosApp.CRM.CallLog do
  use Ash.Resource, domain: ContactosApp.CRM, data_layer: AshPostgres.DataLayer

  postgres do
    table "call_logs"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]
    create :create, accept: [:contact_id, :direction, :duration_seconds, :notes, :called_at]
  end

  attributes do
    uuid_primary_key :id
    attribute :direction, :atom, constraints: [one_of: [:inbound, :outbound]], allow_nil?: false
    attribute :duration_seconds, :integer, default: 0
    attribute :notes, :string
    attribute :called_at, :utc_datetime_usec, allow_nil?: false
  end

  relationships do
    belongs_to :contact, ContactosApp.CRM.Contact, allow_nil?: false, attribute_type: :uuid
  end
end
