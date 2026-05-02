# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidCallingServiceDirectly < RuboCop::Cop::Base
        MSG = 'Service classes can only be called with `execute` class method or by chaining `Service.with_current_user(user).execute`. Calling `new` is forbidden.'.freeze

        def on_send(node)
          receiver = node.receiver
          return if !receiver
          return if !receiver.source.start_with?('Service::')

          case node.method_name
          when :new
            add_offense(node, message: MSG)
          when :with_current_user
            if node.parent&.send_type? && node.parent.method_name == :execute
              return
            end

            add_offense(node, message: MSG)
          end
        end
      end
    end
  end
end
