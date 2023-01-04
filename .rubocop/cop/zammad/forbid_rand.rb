# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ForbidRand < Base
        MSG = <<~ERROR_MESSAGE.freeze
          Please avoid 'rand' if possible. It does not guarantee uniqueness which means that there is a risk of collisions. Possible alternatives:
          - If you need unique values, consider using 'SecureRandom.uuid'.
          - To randomly select a value from a list, use [].sample.
          - To generate random test data that does not need to be unique, you can use 'Faker::*'.
        ERROR_MESSAGE

        def on_send(node)
          add_offense(node) if node.method_name.eql? :rand
        end
      end
    end
  end
end
