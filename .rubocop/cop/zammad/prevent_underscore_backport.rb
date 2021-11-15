# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class PreventUnderscroreBackport < Base
        MSG = <<~ERROR_MESSAGE.freeze
          The method __(...) is not available in current stable.
        ERROR_MESSAGE

        def on_send(node)
          add_offense(node) if node.method_name.eql? :__
        end
      end
    end
  end
end
