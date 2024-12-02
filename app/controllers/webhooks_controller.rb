# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class WebhooksController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def preview
    ticket = TicketPolicy::ReadScope.new(current_user).resolve.last

    render json:   JSON.pretty_generate({
                                          ticket:  TriggerWebhookJob::RecordPayload.generate(ticket),
                                          article: TriggerWebhookJob::RecordPayload.generate(ticket.articles.last),
                                        }),
           status: :ok
  end

  def index
    model_index_render(Webhook, params)
  end

  def show
    model_show_render(Webhook, params)
  end

  def create
    model_create_render(Webhook, params)
  end

  def update
    model_update_render(Webhook, params)
  end

  def destroy
    model_destroy_render(Webhook, params)
  end

  def search
    model_search_render(Webhook, params)
  end

  def pre_defined_webhooks
    render json: Webhook::PreDefined.pre_defined_webhook_definitions, status: :ok
  end

  def replacements
    render json:   TriggerWebhookJob::CustomPayload.replacements(pre_defined_webhook_type: params[:pre_defined_webhook_type]),
           status: :ok
  end
end
