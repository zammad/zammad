# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::BetaUi::SendFeedback < Service::Base
  BETA_UI_FEEDBACK_API_HOST = 'https://beta-ui-feedback.zammad.com'.freeze
  BETA_UI_FEEDBACK_NAME = 'beta-ui-feedback.zammad.com'.freeze
  BETA_UI_FEEDBACK_EMAIL_ADDRESS = 'noreply@beta-ui-feedback.zammad.com'.freeze

  attr_reader :type, :comment, :time_spent, :rating

  def initialize(type:, comment:, time_spent:, rating: nil)
    @type = type
    @comment = comment
    @time_spent = time_spent
    @rating = rating
  end

  def execute
    Service::CheckFeatureEnabled.execute(name: 'ui_desktop_beta_switch')

    token = fetch_form_token

    submit_feedback(token)
  end

  def api_host
    ENV['BETA_UI_FEEDBACK_API_HOST'] || BETA_UI_FEEDBACK_API_HOST
  end

  private

  def fingerprint
    @fingerprint ||= SecureRandom.uuid
  end

  def fqdn
    Setting.get('fqdn')
  end

  def fetch_form_token
    response = UserAgent.post(
      "#{api_host}/api/v1/form_config",
      {
        fingerprint:,
      },
      {
        verify_ssl: true,
        json:       true,
      },
    )

    raise CommunicationError if !response.success?
    raise InvalidTokenError if response.data['token'].blank?

    response.data['token']
  end

  def submit_feedback(token)
    version = Version.get

    response = UserAgent.post(
      "#{api_host}/api/v1/form_submit",
      {
        fingerprint:,
        token:,
        fqdn:,
        feedback_type:       type,
        feedback_text:       comment,
        zammad_version:      version.split('-', 2).first || '',
        zammad_version_full: version,
        time_spent:,
        rating:,
        title:               fqdn,
        body:                comment,
        name:                BETA_UI_FEEDBACK_NAME,
        email:               BETA_UI_FEEDBACK_EMAIL_ADDRESS,
      },
      {
        verify_ssl: true,
        json:       true,
      },
    )

    raise CommunicationError if !response.success?
    raise InvalidFeedbackError if response.data.dig('ticket', 'number').blank?

    true
  end

  class SendFeedbackError < StandardError
    def initialize
      super(__('Sending feedback failed, please try again later.'))
    end
  end

  class CommunicationError < SendFeedbackError; end
  class InvalidTokenError < SendFeedbackError; end
  class InvalidFeedbackError < SendFeedbackError; end

end
