# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidTranslatableMarker < Base
        MSG = <<~ERROR_MESSAGE.freeze
          Don't use __() in Zammad core migrations. Translatable strings should be marked where they are defined, e.g. in the DB seeds.
        ERROR_MESSAGE

        def on_send(node)
          add_offense(node) if node.method_name.eql? :__
        end
      end
    end
  end
end
