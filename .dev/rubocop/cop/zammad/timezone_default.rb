# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class TimezoneDefault < Base
        def on_str(node)
          return if !matching_string?(node)
          return if !matching_node?(node)

          add_offense(node.parent, message: <<~TEXT.chomp)
            Setting.get('timezone_default_sanitized') is removed.
            Please use Setting.get('timezone_default') directly.
          TEXT
        end

        def matching_string?(node)
          node.source == "'timezone_default_sanitized'"
        end

        def matching_node?(node)
          parent = node.parent

          return false if !parent

          parent.receiver&.const_name == 'Setting' && parent.method_name == :get
        end
      end
    end
  end
end
