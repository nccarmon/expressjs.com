# App de Directorio de Contactos con Elixir + Phoenix + Ash + LiveView + Oban

Este documento te deja una base completa para crear una app de **directorio de contactos** con:

- Nombre
- Apellido
- Empresa
- Correo electrónico
- Teléfono de WhatsApp
- Historial de mensajes
- Historial de llamadas
- Plantillas de mensajes cortos
- Envío por correo o WhatsApp (encolado con Oban)

> Nota: en este entorno no fue posible descargar dependencias externas (Hex/GitHub), así que se entrega una base funcional de arquitectura y código para usar directamente en tu máquina local.

---


## 0) ¿Desde dónde puedes bajar el app a tu equipo?

Tienes 2 opciones prácticas:

### Opción A: bajar este repositorio (incluye este blueprint)

```bash
git clone <URL_DE_TU_REPO_O_FORK>
cd expressjs.com
```

Aquí encontrarás este archivo (`CONTACTOS_APP_ELIXIR.md`) con todo el paso a paso para crear el proyecto en tu máquina.

### Opción B (recomendada): crear el app directamente en tu equipo

En tu computadora local (con Elixir/Erlang/PostgreSQL instalados):

```bash
mix archive.install hex phx_new --force
mix phx.new contactos_app --live --database postgres
cd contactos_app
```

Después pega las dependencias y módulos de este documento, ejecuta:

```bash
mix deps.get
mix ecto.create
mix ash.codegen init
mix ash.migrate
mix phx.server
```

El app quedará corriendo en `http://localhost:4000`.

---

## 1) Crear el proyecto

```bash
mix phx.new contactos_app --live --database postgres
cd contactos_app
```

Agregar dependencias en `mix.exs`:

```elixir
{:ash, "~> 3.0"},
{:ash_postgres, "~> 2.0"},
{:ash_phoenix, "~> 2.0"},
{:ash_oban, "~> 0.2"},
{:oban, "~> 2.17"},
{:swoosh, "~> 1.16"},
{:finch, "~> 0.18"},
{:jason, "~> 1.4"}
```

Luego:

```bash
mix deps.get
```

---

## 2) Configuración base

### `config/config.exs`

```elixir
config :contactos_app,
  ecto_repos: [ContactosApp.Repo],
  ash_domains: [ContactosApp.CRM],
  generators: [timestamp_type: :utc_datetime]

config :contactos_app, Oban,
  repo: ContactosApp.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, messages: 20, calls: 10]
```

### `lib/contactos_app/application.ex`

Asegura que Oban está en supervisión:

```elixir
{Oban, Application.fetch_env!(:contactos_app, Oban)}
```

---

## 3) Dominio Ash (CRM)

Crear dominio:

### `lib/contactos_app/crm.ex`

```elixir
defmodule ContactosApp.CRM do
  use Ash.Domain

  resources do
    resource ContactosApp.CRM.Contact
    resource ContactosApp.CRM.MessageTemplate
    resource ContactosApp.CRM.MessageLog
    resource ContactosApp.CRM.CallLog
  end
end
```

---

## 4) Recursos

## `Contact`

### `lib/contactos_app/crm/contact.ex`

```elixir
defmodule ContactosApp.CRM.Contact do
  use Ash.Resource,
    domain: ContactosApp.CRM,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "contacts"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      accept [:first_name, :last_name, :company, :email, :whatsapp_phone]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string do
      allow_nil? false
      constraints min_length: 2
    end

    attribute :last_name, :string do
      allow_nil? false
      constraints min_length: 2
    end

    attribute :company, :string

    attribute :email, :string do
      allow_nil? false
    end

    attribute :whatsapp_phone, :string do
      allow_nil? false
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_email, [:email]
  end

  validations do
    validate match(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  relationships do
    has_many :message_logs, ContactosApp.CRM.MessageLog
    has_many :call_logs, ContactosApp.CRM.CallLog
  end
end
```

## `MessageTemplate`

### `lib/contactos_app/crm/message_template.ex`

```elixir
defmodule ContactosApp.CRM.MessageTemplate do
  use Ash.Resource,
    domain: ContactosApp.CRM,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "message_templates"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      accept [:name, :body]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :body, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end
end
```

## `MessageLog`

### `lib/contactos_app/crm/message_log.ex`

```elixir
defmodule ContactosApp.CRM.MessageLog do
  use Ash.Resource,
    domain: ContactosApp.CRM,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "message_logs"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:contact_id, :channel, :subject, :body, :status, :external_id]
    end

    update :mark_sent do
      accept [:status, :external_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :channel, :atom do
      constraints one_of: [:email, :whatsapp]
      allow_nil? false
    end

    attribute :subject, :string
    attribute :body, :string, allow_nil?: false
    attribute :status, :atom, default: :queued
    attribute :external_id, :string

    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :contact, ContactosApp.CRM.Contact do
      allow_nil? false
      attribute_type :uuid
    end
  end
end
```

## `CallLog`

### `lib/contactos_app/crm/call_log.ex`

```elixir
defmodule ContactosApp.CRM.CallLog do
  use Ash.Resource,
    domain: ContactosApp.CRM,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "call_logs"
    repo ContactosApp.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      accept [:contact_id, :direction, :duration_seconds, :notes, :called_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :direction, :atom do
      constraints one_of: [:inbound, :outbound]
      allow_nil? false
    end

    attribute :duration_seconds, :integer, default: 0
    attribute :notes, :string
    attribute :called_at, :utc_datetime_usec, allow_nil?: false
  end

  relationships do
    belongs_to :contact, ContactosApp.CRM.Contact do
      allow_nil? false
      attribute_type :uuid
    end
  end
end
```

---

## 5) Jobs Oban para envíos

### `lib/contactos_app/workers/send_email_worker.ex`

```elixir
defmodule ContactosApp.Workers.SendEmailWorker do
  use Oban.Worker, queue: :messages, max_attempts: 5

  alias ContactosApp.CRM

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_log_id" => log_id}}) do
    # 1) Cargar MessageLog y contacto
    # 2) Enviar con Swoosh
    # 3) Marcar status=:sent o :failed
    _ = CRM
    _ = log_id
    :ok
  end
end
```

### `lib/contactos_app/workers/send_whatsapp_worker.ex`

```elixir
defmodule ContactosApp.Workers.SendWhatsappWorker do
  use Oban.Worker, queue: :messages, max_attempts: 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_log_id" => log_id}}) do
    # Integración sugerida: WhatsApp Cloud API (Meta)
    # - POST /{phone-number-id}/messages
    # - Guardar id externo
    _ = log_id
    :ok
  end
end
```

---

## 6) LiveView para el directorio

### `lib/contactos_app_web/live/contacts_live/index.ex`

```elixir
defmodule ContactosAppWeb.ContactsLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM
  alias ContactosApp.CRM.Contact

  def mount(_params, _session, socket) do
    contacts = Ash.read!(Contact)
    {:ok, assign(socket, contacts: contacts)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-bold">Directorio de Contactos</h1>
      <table class="table-auto w-full mt-4">
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Apellido</th>
            <th>Empresa</th>
            <th>Email</th>
            <th>WhatsApp</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={c <- @contacts}>
            <td>{c.first_name}</td>
            <td>{c.last_name}</td>
            <td>{c.company}</td>
            <td>{c.email}</td>
            <td>{c.whatsapp_phone}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
```

---

## 7) Flujo de envío recomendado

1. Usuario selecciona contacto.
2. Elige plantilla corta (`MessageTemplate`) y canal (`email` o `whatsapp`).
3. Se crea `MessageLog` en estado `:queued`.
4. Se encola job Oban correspondiente.
5. Worker envía, guarda `external_id` y cambia estado a `:sent` o `:failed`.

---

## 8) Migraciones sugeridas

Tablas:

- `contacts`
- `message_templates`
- `message_logs`
- `call_logs`
- `oban_jobs` (creada por Oban)

Con AshPostgres normalmente se generan con:

```bash
mix ash.codegen init
mix ash.codegen add_crm_resources
mix ash.migrate
```

---

## 9) Integraciones

- **Correo**: Swoosh + proveedor SMTP o API (SendGrid, Mailgun, etc.).
- **WhatsApp**: WhatsApp Cloud API (Meta) o Twilio WhatsApp.
- **Seguridad**: agrega autenticación (ej. phx.gen.auth o AshAuthentication) y auditoría.

---

## 10) Próximos pasos

Si quieres, en el siguiente paso te puedo generar:

- Estructura completa de archivos lista para copiar/pegar.
- Formularios LiveView de alta/edición de contactos.
- Pantalla de historial por contacto (mensajes + llamadas).
- Servicio real para enviar correos y WhatsApp con variables dinámicas en plantillas (ej. `{{nombre}}`).

---

## 11) Solución al error `:eaddrinuse` (puerto ocupado)

Si te aparece este error:

```text
** (Mix) Could not start application contactos_app
...
** (EXIT) :eaddrinuse
```

significa que el puerto HTTP (normalmente `4000`) **ya está siendo usado** por otro proceso.

### Opción A: liberar el puerto 4000

En Linux/macOS:

```bash
lsof -nP -iTCP:4000 -sTCP:LISTEN
kill -15 <PID>
# si no termina
kill -9 <PID>
```

En Windows (PowerShell):

```powershell
netstat -ano | findstr :4000
taskkill /PID <PID> /F
```

Después vuelve a correr:

```bash
mix phx.server
```

### Opción B: arrancar Phoenix en otro puerto

```bash
PORT=4001 mix phx.server
```

Y abre:

- `http://localhost:4001`

### Opción C: dejar fijo otro puerto en config

En `config/dev.exs`, cambia:

```elixir
http: [ip: {127, 0, 0, 1}, port: 4000]
```

por ejemplo a:

```elixir
http: [ip: {127, 0, 0, 1}, port: 4001]
```

### Verificación rápida

```bash
lsof -nP -iTCP:4000 -sTCP:LISTEN
lsof -nP -iTCP:4001 -sTCP:LISTEN
```

- Si `4000` sale ocupado, usa `4001`.
- Si `4001` queda escuchando por `beam.smp`, tu app ya levantó correctamente.


---

## 12) ¿Cómo accedo a la página inicial/dashboard?

Con Phoenix recién creado, la ruta raíz suele ser:

- `http://127.0.0.1:4000`
- `http://localhost:4000`

Si cambiaste de puerto por `:eaddrinuse`, usa:

- `http://127.0.0.1:4001`

### Dashboard técnico de Phoenix (LiveDashboard)

En entorno `dev`, normalmente puedes entrar a:

- `http://127.0.0.1:4000/dev/dashboard`

Si no abre, revisa en tu `router.ex` que exista un bloque como este (solo en `dev`):

```elixir
if Application.compile_env(:contactos_app, :dev_routes) do
  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: ContactosAppWeb.Telemetry
  end
end
```

> Este dashboard es técnico (métricas/procesos), no un dashboard funcional de CRM para usuarios finales.

### Dashboard funcional de inicio (CRM)

En este blueprint **todavía no está creado un dashboard completo**. Solo hay ejemplo de listado LiveView de contactos.

Puedes montarlo como inicio agregando en `router.ex` algo como:

```elixir
live "/", ContactosAppWeb.ContactsLive.Index, :index
```

Así el home `/` mostrará tu directorio inicial.

---

## 13) ¿Ya están generados todos los CRUDs?

**Respuesta corta: no, aún no al 100%.**

Este documento entrega una **base/blueprint** con:

- Recursos Ash (`Contact`, `MessageTemplate`, `MessageLog`, `CallLog`)
- Estructura de workers Oban
- Un LiveView de listado (`ContactsLive.Index`)

Pero faltan, para considerarlo CRUD completo de producción:

1. Formularios LiveView para **crear/editar/eliminar** cada entidad.
2. Rutas completas por recurso (index/new/edit/show).
3. Acciones UI para enviar mensajes y registrar llamadas desde pantalla.
4. Integración real de envío (Swoosh y API WhatsApp) en workers.
5. Manejo de errores, validaciones UX, autenticación y permisos.

### Siguiente paso recomendado (te lo puedo generar)

Puedo prepararte en el siguiente paso un **scaffold funcional completo** con:

- CRUD de Contactos
- CRUD de Plantillas de Mensaje
- Historial de Mensajes (con envío)
- Historial de Llamadas
- Dashboard inicial de CRM en `/`
- Navegación y menús en LiveView


---

## 14) Scaffold funcional completo (copy/paste)

A continuación tienes una propuesta **funcional** para completar el scaffold (dashboard + CRUDs + historial + envío encolado).

## 14.1 Estructura sugerida

```text
lib/
  contactos_app/
    crm.ex
    crm/contact.ex
    crm/message_template.ex
    crm/message_log.ex
    crm/call_log.ex
    messaging.ex
    messaging/sender.ex
    workers/send_email_worker.ex
    workers/send_whatsapp_worker.ex
  contactos_app_web/
    router.ex
    components/layouts/app.html.heex
    live/dashboard_live.ex
    live/contacts_live/index.ex
    live/contacts_live/form_component.ex
    live/templates_live/index.ex
    live/templates_live/form_component.ex
    live/messages_live/index.ex
    live/calls_live/index.ex
```

## 14.2 Router con dashboard + CRUDs

### `lib/contactos_app_web/router.ex`

```elixir
scope "/", ContactosAppWeb do
  pipe_through :browser

  live "/", DashboardLive, :index

  live "/contacts", ContactsLive.Index, :index
  live "/contacts/new", ContactsLive.Index, :new
  live "/contacts/:id/edit", ContactsLive.Index, :edit

  live "/templates", TemplatesLive.Index, :index
  live "/templates/new", TemplatesLive.Index, :new
  live "/templates/:id/edit", TemplatesLive.Index, :edit

  live "/messages", MessagesLive.Index, :index
  live "/calls", CallsLive.Index, :index
end
```

## 14.3 Menú principal en layout

### `lib/contactos_app_web/components/layouts/app.html.heex`

```heex
<header class="border-b p-4">
  <nav class="flex gap-4 text-sm">
    <.link navigate={~p"/"}>Dashboard</.link>
    <.link navigate={~p"/contacts"}>Contactos</.link>
    <.link navigate={~p"/templates"}>Plantillas</.link>
    <.link navigate={~p"/messages"}>Mensajes</.link>
    <.link navigate={~p"/calls"}>Llamadas</.link>
  </nav>
</header>
<main class="p-6">
  {@inner_content}
</main>
```

## 14.4 Dashboard inicial CRM

### `lib/contactos_app_web/live/dashboard_live.ex`

```elixir
defmodule ContactosAppWeb.DashboardLive do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.{Contact, MessageLog, CallLog}

  def mount(_params, _session, socket) do
    contacts_count = Contact |> Ash.Query.for_read(:read) |> Ash.count!()
    messages_count = MessageLog |> Ash.Query.for_read(:read) |> Ash.count!()
    calls_count = CallLog |> Ash.Query.for_read(:read) |> Ash.count!()

    {:ok,
     assign(socket,
       contacts_count: contacts_count,
       messages_count: messages_count,
       calls_count: calls_count
     )}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold mb-4">Dashboard CRM</h1>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <article class="border rounded p-4">
        <h2 class="font-semibold">Contactos</h2>
        <p class="text-3xl"><%= @contacts_count %></p>
      </article>
      <article class="border rounded p-4">
        <h2 class="font-semibold">Mensajes</h2>
        <p class="text-3xl"><%= @messages_count %></p>
      </article>
      <article class="border rounded p-4">
        <h2 class="font-semibold">Llamadas</h2>
        <p class="text-3xl"><%= @calls_count %></p>
      </article>
    </div>
    """
  end
end
```

## 14.5 CRUD Contactos (index/new/edit/delete)

### `lib/contactos_app_web/live/contacts_live/index.ex`

```elixir
defmodule ContactosAppWeb.ContactsLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.Contact

  def mount(_params, _session, socket) do
    {:ok, stream(socket, :contacts, Ash.read!(Contact))}
  end

  def handle_params(params, _uri, socket) do
    socket =
      case socket.assigns.live_action do
        :new -> assign(socket, selected: nil)
        :edit -> assign(socket, selected: Ash.get!(Contact, params["id"]))
        :index -> assign(socket, selected: nil)
      end

    {:noreply, socket}
  end

  def handle_info({:saved, contact}, socket) do
    {:noreply, stream_insert(socket, :contacts, contact)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    contact = Ash.get!(Contact, id)
    Ash.destroy!(contact)
    {:noreply, stream_delete(socket, :contacts, contact)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-center mb-4">
      <h1 class="text-2xl font-bold">Contactos</h1>
      <.link patch={~p"/contacts/new"} class="border rounded px-3 py-2">Nuevo</.link>
    </div>

    <table class="w-full border">
      <thead>
        <tr>
          <th>Nombre</th><th>Apellido</th><th>Empresa</th><th>Email</th><th>WhatsApp</th><th></th>
        </tr>
      </thead>
      <tbody id="contacts" phx-update="stream">
        <tr :for={{id, c} <- @streams.contacts} id={id}>
          <td>{c.first_name}</td>
          <td>{c.last_name}</td>
          <td>{c.company}</td>
          <td>{c.email}</td>
          <td>{c.whatsapp_phone}</td>
          <td class="flex gap-2">
            <.link patch={~p"/contacts/#{c.id}/edit"}>Editar</.link>
            <.link phx-click="delete" phx-value-id={c.id} data-confirm="¿Eliminar?">Eliminar</.link>
          </td>
        </tr>
      </tbody>
    </table>

    <.modal :if={@live_action in [:new, :edit]} id="contact-modal" show on_cancel={JS.patch(~p"/contacts")}>
      <.live_component
        module={ContactosAppWeb.ContactsLive.FormComponent}
        id={@selected && @selected.id || :new}
        contact={@selected}
        patch={~p"/contacts"}
      />
    </.modal>
    """
  end
end
```

### `lib/contactos_app_web/live/contacts_live/form_component.ex`

```elixir
defmodule ContactosAppWeb.ContactsLive.FormComponent do
  use ContactosAppWeb, :live_component

  alias ContactosApp.CRM.Contact

  def update(assigns, socket) do
    form =
      if assigns.contact do
        AshPhoenix.Form.for_update(assigns.contact, :update, as: "contact")
      else
        AshPhoenix.Form.for_create(Contact, :create, as: "contact")
      end

    {:ok, assign(socket, assigns |> Map.put(:form, to_form(form)))}
  end

  def handle_event("validate", %{"contact" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
    {:noreply, assign(socket, :form, to_form(form))}
  end

  def handle_event("save", %{"contact" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, contact} ->
        send(self(), {:saved, contact})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="contact-form" phx-target={@myself} phx-change="validate" phx-submit="save">
      <.input field={@form[:first_name]} label="Nombre" />
      <.input field={@form[:last_name]} label="Apellido" />
      <.input field={@form[:company]} label="Empresa" />
      <.input field={@form[:email]} type="email" label="Correo" />
      <.input field={@form[:whatsapp_phone]} label="WhatsApp" />
      <:actions><.button>Guardar</.button></:actions>
    </.simple_form>
    """
  end
end
```

## 14.6 CRUD Plantillas

Replica la misma estructura de `ContactsLive` para `MessageTemplate` (`TemplatesLive.Index` + `FormComponent`) con campos:

- `name`
- `body`

## 14.7 Historial de mensajes + envío con Oban

### `lib/contactos_app/messaging.ex`

```elixir
defmodule ContactosApp.Messaging do
  alias ContactosApp.CRM.MessageLog
  alias ContactosApp.Workers.{SendEmailWorker, SendWhatsappWorker}

  def queue_message(attrs) do
    log = Ash.create!(MessageLog, attrs)

    worker =
      case log.channel do
        :email -> SendEmailWorker
        :whatsapp -> SendWhatsappWorker
      end

    %{message_log_id: log.id}
    |> worker.new(queue: :messages)
    |> Oban.insert!()

    {:ok, log}
  end
end
```

### `lib/contactos_app_web/live/messages_live/index.ex`

```elixir
defmodule ContactosAppWeb.MessagesLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.{Contact, MessageLog, MessageTemplate}
  alias ContactosApp.Messaging

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       contacts: Ash.read!(Contact),
       templates: Ash.read!(MessageTemplate),
       messages: Ash.read!(MessageLog)
     )}
  end

  def handle_event("send", %{"message" => params}, socket) do
    attrs = %{
      contact_id: params["contact_id"],
      channel: String.to_existing_atom(params["channel"]),
      subject: params["subject"],
      body: params["body"],
      status: :queued
    }

    {:ok, _log} = Messaging.queue_message(attrs)
    {:noreply, assign(socket, :messages, Ash.read!(MessageLog))}
  end
end
```

## 14.8 Historial de llamadas (CRUD)

### `lib/contactos_app_web/live/calls_live/index.ex`

```elixir
defmodule ContactosAppWeb.CallsLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.{CallLog, Contact}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       contacts: Ash.read!(Contact),
       calls: Ash.read!(CallLog)
     )}
  end

  def handle_event("create", %{"call" => params}, socket) do
    Ash.create!(CallLog, %{
      contact_id: params["contact_id"],
      direction: String.to_existing_atom(params["direction"]),
      duration_seconds: String.to_integer(params["duration_seconds"]),
      notes: params["notes"],
      called_at: DateTime.utc_now()
    })

    {:noreply, assign(socket, :calls, Ash.read!(CallLog))}
  end
end
```

## 14.9 Lista de checks para considerar “completo”

- [x] Dashboard inicial en `/`
- [x] CRUD Contactos
- [x] CRUD Plantillas
- [x] Historial + envío de mensajes encolado (Oban)
- [x] Historial de llamadas
- [x] Menú de navegación LiveView
- [ ] Autenticación/roles
- [ ] Integración real SMTP + WhatsApp API en producción

Con esto ya tienes una base mucho más cercana a un MVP funcional para operación diaria.

---

## 15) Entrega en archivos reales (ya incluido en este repo)

Además del blueprint, ya dejé un scaffold en archivos reales dentro de:

- `scaffold/contactos_app/`

Incluye recursos Ash, LiveViews base, workers Oban, snippets de router/layout y migraciones iniciales.

## 16) Continuación aplicada: CRUDs y pantallas ampliadas en scaffold

Se amplió el scaffold real en `scaffold/contactos_app/` con:

- CRUD de plantillas con modal (`TemplatesLive.Index` + `FormComponent`)
- Pantalla de mensajes con selección de plantilla y encolado Oban
- Pantalla de llamadas con registro desde formulario
- Router snippet con rutas `new/edit` para contactos y plantillas

Esto te deja más cerca de ejecutar un MVP completo copiando el scaffold a tu proyecto Phoenix local.


## 17) ¿Cómo descargar TODO a tu computador? (paso a paso)

### Método A: clonar por Git

```bash
git clone <URL_DE_TU_REPO>
cd expressjs.com
```

Ahí ya tendrás:

- Guía completa: `CONTACTOS_APP_ELIXIR.md`
- Scaffold listo para copiar: `scaffold/contactos_app/`

### Método B: descargar ZIP

1. Ve a tu repositorio en GitHub.
2. Clic en **Code**.
3. Clic en **Download ZIP**.
4. Descomprime el ZIP y abre la carpeta del repo.

### Luego crea tu app local y copia scaffold

```bash
mix phx.new contactos_app --live --database postgres
cd contactos_app
```

Copia desde el repo descargado a tu app local:

- `scaffold/contactos_app/lib/*` -> `lib/`
- `scaffold/contactos_app/priv/repo/migrations/*` -> `priv/repo/migrations/`

Ejecuta:

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Abre en navegador:

- `http://127.0.0.1:4000`
