# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::CheckFeatureEnabled < Service::Base
  include Service::Concerns::HandlesSetting

  attr_reader :name, :exception

  def initialize(name: nil, exception: true)
    super()
    @name = name
    @exception = exception
  end

  def execute
    enabled = setting_enabled?(@name)
    return enabled if !@exception

    raise FeatureDisabledError if !enabled
  end

  class FeatureDisabledError < StandardError
    def initialize
      super(__('This feature is not enabled.'))
    end
  end
end
