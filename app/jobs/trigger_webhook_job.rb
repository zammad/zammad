# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob < ApplicationJob

  attr_reader :ticket, :trigger, :article, :changes, :user_id, :execution_type, :event_type

  retry_on TriggerWebhookJob::RequestError, attempts: 5, wait: lambda { |executions|
    executions * 10.seconds
  }

  discard_on(ActiveJob::DeserializationError) do |_job, e|
    Rails.logger.info 'Trigger, Ticket or Article may got removed before TriggerWebhookJob could be executed. Discarding job. See exception for further details.'
    Rails.logger.info e
  end

  def perform(trigger, ticket, article, changes:, user_id:, execution_type:, event_type:)
    @trigger = trigger
    @ticket  = ticket
    @article = article
    @changes    = changes
    @user_id    = user_id
    @execution_type = execution_type
    @event_type = event_type

    return if abort?
    return if request.success?

    raise TriggerWebhookJob::RequestError
  rescue HostnameSafetyCheck::SafetyError => e
    Rails.logger.error "Can't execute Webhook with ID #{webhook_id} for Trigger '#{trigger.name}' with ID #{trigger.id}: #{e.message}"
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
    http_method = (webhook.http_method.presence || 'post').downcase.to_sym
    interpolated_endpoint = interpolate_endpoint

    UserAgent.send(
      http_method,
      interpolated_endpoint,
      payload,
      {
        json:                    true,
        jsonParseDisable:        true,
        open_timeout:            4,
        read_timeout:            30,
        total_timeout:           60,
        headers:                 headers,
        signature_token:         webhook.signature_token,
        verify_ssl:              webhook.ssl_verify,
        user:                    webhook.basic_auth_username,
        password:                webhook.basic_auth_password,
        bearer_token:            webhook.bearer_token,
        do_not_follow_redirects: true,
        log:                     {
          facility: 'webhook',
        },
        validate_safety:         { allow_private: true, allow_loopback: true },
      },
    )
  end

  def headers
    {
      'X-Zammad-Trigger'  => trigger.name,
      'X-Zammad-Delivery' => job_id
    }
  end

  def default_payload
    {
      ticket:  TriggerWebhookJob::RecordPayload.generate(ticket),
      article: TriggerWebhookJob::RecordPayload.generate(article),
    }
  end

  def payload
    return generate_custom_payload if webhook.customized_payload || webhook.pre_defined_webhook_type.present?

    default_payload
  end

  def pre_defined_webhook_payload
    Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook.payload(webhook.pre_defined_webhook_type)
  end

  def generate_custom_payload
    payload = webhook.customized_payload ? webhook.custom_payload : pre_defined_webhook_payload
    return default_payload if payload.nil?

    tracks = { ticket:, article: }

    # Use the new interpolation service
    interpolator = Service::Template::Interpolation::Interpolator::Webhook.new(
      template:                       payload,
      tracks:,
      additional_track_generate_data: webhook_data,
    )

    result = interpolator.execute
    return result if webhook.customized_payload

    # Handle post_replace for pre-defined webhooks
    pre_defined_webhook = "Webhook::PreDefined::#{webhook.pre_defined_webhook_type}".constantize.new
    return result if !pre_defined_webhook.respond_to?(:post_replace)

    pre_defined_webhook.post_replace(result, tracks)
  end

  def webhook_data
    {
      event:   {
        type:      event_type,
        execution: execution_type,
        changes:,
        user_id:
      },
      webhook: webhook
    }
  end

  def interpolate_endpoint
    endpoint = webhook.endpoint

    return endpoint if !endpoint.match?(%r{#\{[a-z0-9_.?!]+\}})

    tracks = { ticket:, article: }

    # Use the interpolation service for scanning and parsing
    interpolator = Service::Template::Interpolation::Interpolator.new(
      template: endpoint,
      tracks:,
      mode:     :string,
    )

    interpolator.execute
  end
end
