# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3346Xoauth2TokenNotFetched < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Channel.where(area: ['Google::Account', 'Microsoft365::Account']).find_each do |channel|
      next if skip?(channel)

      begin
        channel.refresh_xoauth2!
      rescue => e
        Rails.logger.error e
      end
    end
  end

  private

  def skip?(channel)
    return true if channel.options.blank?
    return true if channel.options.dig(:inbound, :options, :auth_type) != 'XOAUTH2'

    channel.options[:inbound][:options][:password].present?
  end
end
