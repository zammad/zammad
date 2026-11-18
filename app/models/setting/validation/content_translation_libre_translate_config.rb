# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::ContentTranslationLibreTranslateConfig < Setting::Validation::ContentTranslationBackendConfig

  private

  def backend
    Service::ContentTranslation::Backend::LibreTranslate
  end

end
