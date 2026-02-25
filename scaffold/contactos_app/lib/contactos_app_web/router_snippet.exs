# Agregar dentro de scope "/", ContactosAppWeb do
live "/", DashboardLive, :index

live "/contacts", ContactsLive.Index, :index
live "/contacts/new", ContactsLive.Index, :new
live "/contacts/:id/edit", ContactsLive.Index, :edit

live "/templates", TemplatesLive.Index, :index
live "/templates/new", TemplatesLive.Index, :new
live "/templates/:id/edit", TemplatesLive.Index, :edit

live "/messages", MessagesLive.Index, :index
live "/calls", CallsLive.Index, :index
