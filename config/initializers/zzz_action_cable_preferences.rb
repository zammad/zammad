# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative '../../lib/zammad/service/redis'

Rails.application.config.action_cable.cable = {
  adapter:        :redis,
  channel_prefix: "zammad_#{Rails.env}",
  **Zammad::Service::Redis.config,
}

begin
  Zammad::Service::Redis.new.ping
rescue Redis::CannotConnectError => e
  warn 'There was an error trying to connect to Redis.'
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
