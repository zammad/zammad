# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
  require 'redis'
  require 'hiredis'

  # If REDIS_URL is not set, fall back to default port / localhost, to ease configuration
  #   for simple installations.
  redis_url = ENV['REDIS_URL'].presence || 'redis://localhost:6379'
  Rails.application.config.action_cable.cable = {
    adapter:        :redis,
    driver:         :hiredis,
    url:            redis_url,
    channel_prefix: "zammad_#{Rails.env}",
  }
  begin
    Redis.new(driver: :hiredis, url: redis_url).ping
    Rails.logger.info { "ActionCable is using the redis instance at #{redis_url}." }
  rescue Redis::CannotConnectError => e
    warn "There was an error trying to connect to Redis via #{redis_url}."
    if ENV['REDIS_URL'].present?
      warn 'Please make sure Redis is available.'
    else
      warn 'Please provide a Redis instance at localhost:6379 or set REDIS_URL to point to a different location.'
    end
    warn e.inspect
    exit! # rubocop:disable Rails/Exit
  end
end
