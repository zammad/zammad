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

  def perform(trigger, ticket, article)
    @trigger = trigger
    @ticket  = ticket
    @article = article

    return if request.success?

    raise TriggerWebhookJob::RequestError
  end

  private

  def request
    UserAgent.post(
      config['endpoint'],
      payload,
      {
        json:             true,
        jsonParseDisable: true,
        open_timeout:     4,
        read_timeout:     30,
        total_timeout:    60,
        headers:          headers,
        signature_token:  config['token'],
        verify_ssl:       verify_ssl?,
        log:              {
          facility: 'webhook',
        },
      },
    )
  end

  def config
    @config ||= trigger.perform['notification.webhook']
  end

  def verify_ssl?
    config.fetch('verify_ssl', false).present?
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
