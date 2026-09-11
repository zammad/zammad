# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A blank config passes - it is how the service is removed. Anything else has to name a backend
# and carry what that backend needs, so the flag never points at a config that cannot run.
class Setting::Validation::ContentTranslationServiceConfig < Setting::Validation::Base

  def run
    return result_success if value.blank?
    return result_failed(__('Translation service is missing')) if provider.blank?
    return result_failed(__('Translation service is not supported')) if backend.nil?
    return result_failed(__('Translation service configuration is incomplete')) if missing_keys.any?

    result_success
  end

  private

  def config
    @config ||= value.to_h.with_indifferent_access
  end

  def provider
    config[:provider]
  end

  def backend
    @backend ||= Service::ContentTranslation::Backend.by_name(provider)
  end

  def missing_keys
    backend.required_config_keys.select { |key| config[key].blank? }
  end

end
