# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The config of one translation backend. A blank config passes - it is how the credentials are
# removed - but not while that backend is the active one, which would then run without them.
# Anything else has to carry what the backend needs and be accepted by its service.
class Setting::Validation::ContentTranslationBackendConfig < Setting::Validation::Base

  def run
    return result_blank if value.blank?
    return result_failed(__('Translation service configuration is incomplete')) if !backend.config_complete?(config)

    backend.ping!(config)

    result_success
  rescue Service::ContentTranslation::Backend::Base::Error => e
    result_failed(e.message)
  end

  private

  def backend
    raise NotImplementedError
  end

  def result_blank
    return result_failed(__('The configuration of the active translation service cannot be removed')) if active?

    result_success
  end

  def active?
    Service::ContentTranslation::Backend.by_name(Service::ContentTranslation::Backend.locked_provider_name) == backend
  end

  def config
    @config ||= value.to_h.with_indifferent_access
  end

end
