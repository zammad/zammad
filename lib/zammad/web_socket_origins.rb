# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  class WebSocketOrigins

    # The configured Zammad origins accepted by both ActionCable and the legacy websocket server.
    def self.configured
      [Setting.get('fqdn'), Setting.get('alternative_fqdn')].compact_blank.map { "#{Setting.get('http_type')}://#{it}" }
    end
  end
end
