# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The flag may only say that a translation service is configured while the config names one that
# resolves; otherwise the agent side would offer a translation that cannot run.
class Setting::Validation::ContentTranslationService < Setting::Validation::Base

  def run
    return result_success if !value
    return result_success if Service::ContentTranslation::Backend.configured?

    result_failed(__('Translation service is missing'))
  end

end
