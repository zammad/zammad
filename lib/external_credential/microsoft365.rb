# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::Microsoft365 < ExternalCredential::MicrosoftBase
  def self.channel_area
    'Microsoft365::Account'.freeze
  end

  def self.error_missing_app_configuration
    __('No Microsoft 365 app configured!')
  end

  def self.authorize_scope
    'https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access openid profile email'
  end

  def self.channel_migration_possible?
    true
  end

  def self.channel_options_inbound(user_data, _account_data)
    {
      adapter: 'imap',
      options: {
        auth_type:  'XOAUTH2',
        host:       'outlook.office365.com',
        ssl:        'ssl',
        ssl_verify: true,
        user:       user_data[:preferred_username],
      },
    }
  end

  def self.channel_options_outbound(user_data, _account_data)
    {
      adapter: 'smtp',
      options: {
        host:           'smtp.office365.com',
        port:           587,
        user:           user_data[:preferred_username],
        authentication: 'xoauth2',
        ssl_verify:     true
      },
    }
  end

  def self.find_migration_channel(user_data)
    migrate_channel = nil
    Channel.where(area: 'Email::Account').find_each do |channel|
      next if channel.options.dig(:inbound, :options, :host)&.downcase != 'outlook.office365.com'
      next if channel.options.dig(:outbound, :options, :host)&.downcase != 'smtp.office365.com'
      next if channel.options.dig(:outbound, :options, :user)&.downcase != user_data[:preferred_username].downcase && channel.options.dig(:outbound, :email)&.downcase != user_data[:preferred_username].downcase

      migrate_channel = channel

      break
    end

    migrate_channel
  end

  def self.execute_channel_migration(migrate_channel, channel_options)
    channel_options[:inbound][:options][:folder]         = migrate_channel.options[:inbound][:options][:folder]
    channel_options[:inbound][:options][:keep_on_server] = migrate_channel.options[:inbound][:options][:keep_on_server]

    backup = {
      attributes:  {
        area:         migrate_channel.area,
        options:      migrate_channel.options,
        last_log_in:  migrate_channel.last_log_in,
        last_log_out: migrate_channel.last_log_out,
        status_in:    migrate_channel.status_in,
        status_out:   migrate_channel.status_out,
      },
      migrated_at: Time.zone.now,
    }

    migrate_channel.update(
      area:         channel_area,
      options:      channel_options.merge(backup_imap_classic: backup),
      last_log_in:  nil,
      last_log_out: nil,
    )

    migrate_channel
  end
end
