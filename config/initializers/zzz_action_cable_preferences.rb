# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  Zammad::SafeMode.continue_or_exit!
end

Rails.application.reloader.to_prepare do
  begin
    Rails.application.config.action_cable.allow_same_origin_as_host = true
    # Support for configurations where the HTTP_HOST header is not correctly forwarded:
    request_origins = [%r{https?://localhost:\d+}]
    request_origins << "#{Setting.get('http_type')}://#{Setting.get('fqdn')}"
    Rails.application.config.action_cable.allowed_request_origins = request_origins
    Rails.application.config.action_cable.disable_request_forgery_protection = true if !Rails.env.production?
    Rails.logger.info { "ActionCable is configured to accept requests from #{request_origins.join(', ')}." }
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    Rails.logger.warn { "Database doesn't exist. Skipping allowed_request_origins configuration." }
  end
end
