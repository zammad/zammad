# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::System::SetEmailNotificationConfiguration < Service::Base
  # Setup Email Notification channel configuration
  #
  # @param [String] adapter sendmail or smtp
  # @param [Hash] new_configuration email server configuration, empty unless adapter is smtp
  # @option new_configuration [String] :host SMTP server address
  # @option new_configuration [String] :port SMTP server port
  # @option new_configuration [Boolean] :ssl Wether SMTP ses TLS/SSL
  # @option new_configuration [String] :user login of SMTP server
  # @option new_configuration [String] :password of SMTP server
  # @option new_configuration [Boolean] :ssl_verify Wether SSL verification is performed
  def initialize(adapter:, new_configuration:)
    super()

    @adapter = adapter
    @new_configuration = new_configuration
  end

  def execute
    # There're two instances of Email::Notification for historical easons
    # One for SMTP and one for Sendmail.
    # However, this feature is not used anywhere.
    # At some point it may be good to clean this up to simply use a single instance
    # and set adapter as needed.
    ActiveRecord::Base.transaction do
      Channel
        .where(area: 'Email::Notification')
        .each { update_single_channel(_1) }
    end

    true
  end

  private

  def update_single_channel(channel)
    is_matching_adapter = @adapter.casecmp? channel.options.dig(:outbound, :adapter)

    channel.active = is_matching_adapter

    if is_matching_adapter
      channel.options = {
        outbound: {
          adapter: @adapter,
          options: @new_configuration,
        },
      }

      channel.status_out   = 'ok'
      channel.last_log_out = nil
    end

    channel.save!
  end
end
