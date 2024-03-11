# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::TicketArticleValidator
  class Backend
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def validate
      return if !validator_applies?

      validator_names.each { |elem| send(elem) }
    end

    private

    def validator_applies?
      true
    end

    def validator_names
      methods.select { |elem| elem.starts_with? 'validate_' }
    end
  end
end
