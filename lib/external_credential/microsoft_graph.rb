# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::MicrosoftGraph < ExternalCredential::MicrosoftBase
  def self.channel_area
    'MicrosoftGraph::Account'.freeze
  end

  def self.error_missing_app_configuration
    __('No Microsoft Graph app configured!')
  end

  def self.authorize_scope
    'offline_access openid profile email mail.readwrite mail.readwrite.shared mail.send mail.send.shared'
  end

  def self.channel_options_inbound(user_data, account_data)
    {
      adapter: 'microsoft_graph_inbound',
      options: {
        user:           user_data[:preferred_username],
        shared_mailbox: account_data[:shared_mailbox],
      }.compact_blank,
    }
  end

  def self.channel_options_outbound(user_data, account_data)
    {
      adapter: 'microsoft_graph_outbound',
      options: {
        user:           user_data[:preferred_username],
        shared_mailbox: account_data[:shared_mailbox],
      }.compact_blank,
    }
  end
end
