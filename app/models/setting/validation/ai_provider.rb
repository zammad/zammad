# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::AIProvider < Setting::Validation::Base

  def run
    return result_success if !value
    # Tolerate the pre-migration schema: on upgrades this validator runs before
    # CreateAIProviderConnections (Issue5998AIProviderSettingValidation saves the
    # setting earlier in the migration chain).
    return result_success if !AI::ProviderConnection.table_exists?
    return result_success if AI::ProviderConnection.exists?

    result_failed(__('AI provider is missing'))
  end

end
