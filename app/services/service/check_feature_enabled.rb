# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::CheckFeatureEnabled < Service::Base
  attr_reader :name, :exception, :custom_exception_class, :custom_error_message

  DEFAULT_ERROR_MESSAGE = __('This feature is not enabled.').freeze

  def initialize(name: nil, exception: true, custom_error_message: nil, custom_exception_class: nil)
    super()

    @name                   = name
    @exception              = exception
    @custom_error_message   = custom_error_message
    @custom_exception_class = custom_exception_class
  end

  def execute
    return enabled? if !exception
    return if satisfied?

    raise_exception!
  end

  private

  def enabled?
    @enabled ||= !!Setting.get(name)
  end

  def satisfied?
    @satisfied ||= case exception
                   when :on_enabled
                     !enabled?
                   else
                     enabled?
                   end
  end

  def raise_exception!
    klass   = custom_exception_class || FeatureDisabledError
    message = custom_error_message || DEFAULT_ERROR_MESSAGE

    raise klass, message
  end

  class FeatureDisabledError < StandardError
    def initialize(message = nil)
      super(message || DEFAULT_ERROR_MESSAGE)
    end
  end
end
