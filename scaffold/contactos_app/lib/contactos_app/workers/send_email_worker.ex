defmodule ContactosApp.Workers.SendEmailWorker do
  use Oban.Worker, queue: :messages

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_log_id" => _id}}) do
    # Integrar Swoosh aquí
    :ok
  end
end
