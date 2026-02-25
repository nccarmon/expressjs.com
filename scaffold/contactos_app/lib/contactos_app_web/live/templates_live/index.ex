defmodule ContactosAppWeb.TemplatesLive.Index do
  use ContactosAppWeb, :live_view

  alias ContactosApp.CRM.MessageTemplate

  def mount(_, _, socket) do
    {:ok, stream(socket, :templates, Ash.read!(MessageTemplate))}
  end

  def handle_params(params, _uri, socket) do
    selected =
      case socket.assigns.live_action do
        :new -> nil
        :edit -> Ash.get!(MessageTemplate, params["id"])
        :index -> nil
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_info({:saved, template}, socket) do
    {:noreply, stream_insert(socket, :templates, template)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    template = Ash.get!(MessageTemplate, id)
    Ash.destroy!(template)

    {:noreply, stream_delete(socket, :templates, template)}
  end

  def render(assigns) do
    ~H"""
    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-semibold">Plantillas de Mensajes</h1>
        <.link patch={~p"/templates/new"} class="rounded border px-3 py-1.5">Nueva plantilla</.link>
      </div>

      <table class="w-full border-collapse border">
        <thead>
          <tr>
            <th class="border p-2 text-left">Nombre</th>
            <th class="border p-2 text-left">Mensaje</th>
            <th class="border p-2">Acciones</th>
          </tr>
        </thead>
        <tbody id="templates" phx-update="stream">
          <tr :for={{row_id, template} <- @streams.templates} id={row_id}>
            <td class="border p-2">{template.name}</td>
            <td class="border p-2">{template.body}</td>
            <td class="border p-2 text-center">
              <.link patch={~p"/templates/#{template.id}/edit"} class="mr-3">Editar</.link>
              <.link phx-click="delete" phx-value-id={template.id} data-confirm="¿Eliminar plantilla?">Eliminar</.link>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <.modal :if={@live_action in [:new, :edit]} id="template-modal" show on_cancel={JS.patch(~p"/templates")}>
      <.live_component
        module={ContactosAppWeb.TemplatesLive.FormComponent}
        id={@selected && @selected.id || :new}
        template={@selected}
        patch={~p"/templates"}
      />
    </.modal>
    """
  end
end
