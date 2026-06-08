# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module GraphqlValidations
  module AliasesCount
    def initialize(*)
      super

      @aliases_count = 0
    end

    def on_field(node, parent)
      if node.alias
        @aliases_count += 1
        if @aliases_count > @schema.max_aliases_count
          raise GraphqlValidations::Error, "Too many aliases given (maximum is #{@schema.max_aliases_count})"
        end
      end

      super
    end
  end
end
