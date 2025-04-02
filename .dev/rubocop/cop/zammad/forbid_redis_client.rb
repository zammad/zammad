# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidRedisClient < Base
        MSG = 'Do not use Redis.new directly. Use Zammad::Service::Redis.new instead.'.freeze

        def_node_matcher :redis_client_usage?, <<~PATTERN
          (send (const nil? :Redis) :new)
        PATTERN

        def on_send(node)
          add_offense(node, message: MSG) if redis_client_usage?(node)
        end
      end
    end
  end
end
