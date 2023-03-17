# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3964InboundFixOptions < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Channel.where(area: ['Email::Account', 'Google::Account', 'Microsoft365::Account']).find_each do |channel|
      ssl = channel.options.dig(:inbound, :options, :ssl)
      next if ssl.nil?

      channel.options[:inbound][:options][:ssl] = if ssl == true
                                                    'ssl'
                                                  else
                                                    'off'
                                                  end

      channel.save!
    end
  end
end
