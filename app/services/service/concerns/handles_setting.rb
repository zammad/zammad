# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Service::Concerns::HandlesSetting
  extend ActiveSupport::Concern

  class SettingError < StandardError; end

  included do
    def setting_enabled?(name)
      Setting.get(name)
    end

    def setting_disabled?(name)
      !setting_enabled?(name)
    end

    def setting_enabled!(name)
      raise SettingError, __('This setting is not enabled.') if setting_disabled?(name)
    end

    def setting_disabled!(name)
      raise SettingError, __('This setting is not disabled.') if setting_enabled?(name)
    end

    def setting_get(name)
      Setting.find_by(name: name)
    end
  end
end
