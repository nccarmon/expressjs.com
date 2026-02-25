defmodule ContactosAppWeb.TemplatesLive.FormComponent do
  use ContactosAppWeb, :live_component

  alias ContactosApp.CRM.MessageTemplate

  def update(assigns, socket) do
    form =
      if assigns.template do
        AshPhoenix.Form.for_update(assigns.template, :update, as: "template")
      else
        AshPhoenix.Form.for_create(MessageTemplate, :create, as: "template")
      end

    {:ok, assign(socket, assigns |> Map.put(:form, to_form(form)))}
  end

  def handle_event("validate", %{"template" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
    {:noreply, assign(socket, :form, to_form(form))}
  end

  def handle_event("save", %{"template" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, template} ->
        send(self(), {:saved, template})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  def render(assigns) do
    ~H"""
    <.simple_form for={@form} id="template-form" phx-target={@myself} phx-change="validate" phx-submit="save">
      <.input field={@form[:name]} label="Nombre" />
      <.input field={@form[:body]} type="textarea" label="Mensaje" />
      <:actions>
        <.button>Guardar plantilla</.button>
      </:actions>
    </.simple_form>
    """
  end
end
