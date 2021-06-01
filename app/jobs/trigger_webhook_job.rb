# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggerWebhookJob < ApplicationJob

  USER_ATTRIBUTE_BLACKLIST = %w[
    last_login
    login_failed
    password
    preferences
    group_ids
    groups
    authorization_ids
    authorizations
  ].freeze

  attr_reader :ticket, :trigger, :article

  retry_on TriggerWebhookJob::RequestError, attempts: 5, wait: lambda { |executions|
    executions * 10.seconds
  }

  discard_on(ActiveJob::DeserializationError) do |_job, e|
    Rails.logger.info 'Trigger, Ticket or Article may got removed before TriggerWebhookJob could be executed. Discarding job. See exception for further details.'
    Rails.logger.info e
  end

  def perform(trigger, ticket, article)
    @trigger = trigger
    @ticket  = ticket
    @article = article

    return if abort?
    return if request.success?

    raise TriggerWebhookJob::RequestError
  end

  private

  def abort?
    if webhook_id.blank?
      log_wrong_trigger_config
      return true
    elsif webhook.blank?
      log_not_existing_webhook
      return true
    end

    false
  end

  def webhook_id
    @webhook_id ||= trigger.perform.dig('notification.webhook', 'webhook_id')
  end

  def webhook
    @webhook ||= begin
      Webhook.find_by(
        id:     webhook_id,
        active: true
      )
    end
  end

  def log_wrong_trigger_config
    Rails.logger.error "Can't find webhook_id for Trigger '#{trigger.name}' with ID #{trigger.id}"
  end

  def log_not_existing_webhook
    Rails.logger.error "Can't find Webhook for ID #{webhook_id} configured in Trigger '#{trigger.name}' with ID #{trigger.id}"
  end

  def request
    UserAgent.post(
      webhook.endpoint,
      payload,
      {
        json:             true,
        jsonParseDisable: true,
        open_timeout:     4,
        read_timeout:     30,
        total_timeout:    60,
        headers:          headers,
        signature_token:  webhook.signature_token,
        verify_ssl:       webhook.ssl_verify,
        log:              {
          facility: 'webhook',
        },
      },
    )
  end

  def headers
    {
      'X-Zammad-Trigger'  => trigger.name,
      'X-Zammad-Delivery' => job_id
    }
  end

  def payload
    {
      ticket:  TriggerWebhookJob::RecordPayload.generate(ticket),
      article: TriggerWebhookJob::RecordPayload.generate(article),
    }
  end
end
