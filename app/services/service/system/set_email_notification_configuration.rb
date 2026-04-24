# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    @adapter = adapter
    @new_configuration = new_configuration
    @microsoft_graph_auth = microsoft_graph_auth
  end

  def execute
    ActiveRecord::Base.transaction do
      Channel
        .where(area: 'Email::Notification')
        .each { update_single_channel(it) }
    end

    true
  end

  private

  def update_single_channel(channel)
    is_matching_adapter = @adapter.casecmp? channel.options.dig(:outbound, :adapter)

    channel.active = is_matching_adapter

    if is_matching_adapter
      if @adapter == 'microsoft_graph_outbound'
        channel.options = build_microsoft_graph_options
      else
        channel.options = {
          outbound: {
            adapter: @adapter,
            options: @new_configuration,
          },
        }
      end

      channel.status_out   = 'ok'
      channel.last_log_out = nil
    end

    channel.save!
  end

  def build_microsoft_graph_options
    outbound_options = {
      user: @new_configuration[:user] || @new_configuration['user'],
    }

    shared_mailbox = @new_configuration[:shared_mailbox].presence || @new_configuration['shared_mailbox'].presence
    outbound_options[:shared_mailbox] = shared_mailbox if shared_mailbox

    {
      outbound: {
        adapter: 'microsoft_graph_outbound',
        options: outbound_options.compact_blank,
      },
      auth:     @microsoft_graph_auth,
    }
  end
end
