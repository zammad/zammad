# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2460FixCorruptedTwitterIds < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Channel.where(area: 'Twitter::Account').each do |channel|

      client = nil
      begin
        client = Twitter::REST::Client.new do |config|
          config.consumer_key        = channel.options['auth']['consumer_key']
          config.consumer_secret     = channel.options['auth']['consumer_secret']
          config.access_token        = channel.options['auth']['oauth_token']
          config.access_token_secret = channel.options['auth']['oauth_token_secret']
        end
      rescue => e
        Rails.logger.error "Error while trying to update corrupted Twitter User ID: #{e.message}"
      end

      next if client.nil?

      channel.options['user']['id'] = client.user.id.to_s

      channel.save!
    end
  end
end
