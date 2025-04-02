# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SetMailSSLDefault < ActiveRecord::Migration[6.1]

  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_channels %w[Google::Account Microsoft365::Account], true
    update_channels %w[Email::Account Email::Notification], false
  end

  def update_channels(areas, target_value)
    adapters = %w[pop3 imap smtp]
    directions = %i[inbound outbound]

    Channel
      .where(area: areas)
      .each do |channel|
        directions.each do |dir|
          next if adapters.exclude?(channel.options.dig(dir, :adapter))
          next if !channel.options[dir].key? :options

          channel.options[dir][:options][:ssl_verify] = target_value
        end
        channel.save!
      end
  end
end
