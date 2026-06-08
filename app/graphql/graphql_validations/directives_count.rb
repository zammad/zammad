# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module GraphqlValidations
  module DirectivesCount
    MAX_DIRECTIVES_COUNT = 5

    def initialize(*)
      super

      @directives_count = 0
    end

    def on_directive(node, parent)
      @directives_count += 1

      if @directives_count > @schema.max_directives_count
        raise GraphqlValidations::Error, "Too many directives given (maximum is #{@schema.max_directives_count})"
      end

      super
    end
  end
end
