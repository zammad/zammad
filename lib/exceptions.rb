# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Exceptions

  class NotAuthorized < StandardError; end

  class Forbidden < StandardError; end

  class UnprocessableEntity < StandardError; end

  class InvalidAttribute < StandardError
    attr_reader :attribute

    def initialize(attribute, message)
      super(message)
      @attribute = attribute
    end
  end

  class MissingAttribute < StandardError
    attr_reader :attribute

    def initialize(attribute, message)
      super(message)
      @attribute = attribute
    end
  end

  class ApplicationModel < UnprocessableEntity
    attr_reader :record

    def initialize(record, message)
      super(message)
      @record = record
    end
  end

  def self.policy_class
    ExceptionsPolicy
  end

end
