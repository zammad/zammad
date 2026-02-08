# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesSettingCheck
  extend ActiveSupport::Concern

  included do
    class_attribute :required_enabled_settings, default: []
    class_attribute :required_disabled_settings, default: []
  end

  class_methods do
    def requires_enabled_setting(name, error_message: nil)
      elem = { name:, error_message: }
      self.required_enabled_settings = required_enabled_settings + [elem]
    end

    def requires_disabled_setting(name, error_message: nil)
      elem = { name:, error_message: }
      self.required_disabled_settings = required_disabled_settings + [elem]
    end
  end

  def ready?(...)
    super && validate_settings
  end

  private

  def validate_settings
    required_enabled_settings.each do |elem|
      Service::CheckFeatureEnabled
        .new(
          name:                   elem[:name],
          custom_exception_class: Exceptions::Forbidden,
          custom_error_message:   elem[:error_message]
        )
        .execute
    end

    required_disabled_settings.each do |elem|
      Service::CheckFeatureEnabled
        .new(
          name:                   elem[:name],
          custom_exception_class: Exceptions::Forbidden,
          exception:              :on_enabled,
          custom_error_message:   elem[:error_message]
        )
        .execute
    end

    true
  end
end
