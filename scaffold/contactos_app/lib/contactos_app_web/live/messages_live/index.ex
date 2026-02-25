defmodule ContactosAppWeb.MessagesLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.{Contact, MessageLog, MessageTemplate}
  alias ContactosApp.Messaging

  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       contacts: Ash.read!(Contact),
       templates: Ash.read!(MessageTemplate),
       messages: Ash.read!(MessageLog),
       form: to_form(%{"channel" => "email"}, as: :message)
     )}
  end

  def handle_event("use_template", %{"id" => template_id}, socket) do
    template = Ash.get!(MessageTemplate, template_id)
    params = Map.put(socket.assigns.form.params || %{}, "body", template.body)

    {:noreply, assign(socket, :form, to_form(params, as: :message))}
  end

  def handle_event("send", %{"message" => params}, socket) do
    attrs = %{
      contact_id: params["contact_id"],
      channel: String.to_atom(params["channel"]),
      subject: params["subject"],
      body: params["body"],
      status: :queued
    }

    {:ok, _} = Messaging.queue_message(attrs)

    {:noreply,
     socket
     |> put_flash(:info, "Mensaje encolado correctamente")
     |> assign(:messages, Ash.read!(MessageLog))
     |> assign(:form, to_form(%{"channel" => "email"}, as: :message))}
  end

  def render(assigns) do
    ~H"""
    <section class="space-y-6">
      <h1 class="text-xl font-semibold">Mensajes</h1>

      <.simple_form for={@form} id="message-form" phx-submit="send">
        <.input field={@form[:contact_id]} type="select" label="Contacto" options={Enum.map(@contacts, &{"#{&1.first_name} #{&1.last_name}", &1.id})} />
        <.input field={@form[:channel]} type="select" label="Canal" options={[{"Email", "email"}, {"WhatsApp", "whatsapp"}]} />
        <.input field={@form[:subject]} label="Asunto (solo email)" />
        <.input field={@form[:body]} type="textarea" label="Mensaje" />
        <:actions>
          <.button>Enviar</.button>
        </:actions>
      </.simple_form>

      <div>
        <h2 class="font-medium mb-2">Plantillas rápidas</h2>
        <div class="flex gap-2 flex-wrap">
          <button :for={template <- @templates} type="button" phx-click="use_template" phx-value-id={template.id} class="rounded border px-2 py-1">
            {template.name}
          </button>
        </div>
      </div>

      <div>
        <h2 class="font-medium mb-2">Historial</h2>
        <ul class="space-y-2">
          <li :for={msg <- @messages} class="border rounded p-2">
            <strong>{msg.channel}</strong> - {msg.status}
            <p>{msg.body}</p>
          </li>
        </ul>
      </div>
    </section>
    """
  end
end
