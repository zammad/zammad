# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The active provider has to name a backend whose own config carries what it needs, so switching
# to it never activates a provider without credentials. Those were proven when its config was stored.
class Setting::Validation::ContentTranslationProvider < Setting::Validation::Base

  def run
    # Held while the config is read below, which is not removed without this lock either.
    Service::ContentTranslation::Backend.locked_provider_name

    return removal_result if value.blank?
    return result_failed(__('Translation service is not supported')) if backend.nil?
    return result_failed(__('Translation service configuration is incomplete')) if !backend.config_complete?(stored_config)

    result_success
  end

  private

  # The service flag is validated only when it is written itself, so the provider guards it here.
  def removal_result
    return result_success if !Setting.get('content_translation_service')

    result_failed(__('Translation service must be switched off before its provider is removed'))
  end

  def backend
    return if !value.is_a?(String)

    @backend ||= Service::ContentTranslation::Backend.by_name(value)
  end

  # From the row: the cache of this process may not have seen yet what another process stored.
  def stored_config
    @stored_config ||= Setting.find_by(name: backend.config_setting_name)&.state_current&.dig(:value).to_h.with_indifferent_access
  end

end
