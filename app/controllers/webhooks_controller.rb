# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class WebhooksController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def preview
    access_condition = Ticket.access_condition(current_user, 'read')

    ticket = Ticket.where(access_condition).last

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
end
