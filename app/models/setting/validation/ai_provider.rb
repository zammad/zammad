# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::AIProvider < Setting::Validation::Base

  def run
    return result_success if !value
    return result_success if value && Setting.get('ai_provider_config').present?

    result_failed(__('AI provider is missing'))
  end

end
