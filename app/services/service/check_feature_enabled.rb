# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::CheckFeatureEnabled < Service::Base
  include Service::Concerns::HandlesSetting

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
    enabled = setting_enabled?(@name)
    return enabled if !@exception

    raise @custom_exception_class, (@custom_error_message || DEFAULT_ERROR_MESSAGE) if @custom_exception_class && !enabled
    raise FeatureDisabledError, @custom_error_message if !enabled
  end

  class FeatureDisabledError < StandardError
    def initialize(message = nil)
      super(message || DEFAULT_ERROR_MESSAGE)
    end
  end
end
