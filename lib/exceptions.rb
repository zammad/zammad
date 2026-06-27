# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Exceptions

  class NotAuthorized < StandardError; end

  class InvalidCSRFToken < NotAuthorized
    def initialize
      super(__('CSRF token verification failed.'))
    end
  end

  class Forbidden < StandardError; end

  class UnprocessableContent < StandardError
    attr_reader :content

    def initialize(message, content = nil)
      super(message)
      @content = content
    end
  end

  class UnprocessableEntity < UnprocessableContent
    def initialize(...)
      ActiveSupport::Deprecation.new.warn('Exceptions::UnprocessableEntity is deprecated and will be removed in Zammad 8.0. Please use Exceptions::UnprocessableContent instead.')
      super
    end
  end

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

  class ApplicationModel < UnprocessableContent
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
