# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module AIProviderHelper
  # @param provider [String] (e.g., 'zammad_ai'[DEFAULT], 'open_ai', 'azure', 'anthropic', 'mistral')
  # @param token [String] API token for the AI provider
  # @param additional_config [Hash] Additional configuration options including :token
  def setup_ai_provider(provider = 'zammad_ai', token: nil, **additional_config)
    config = {
      provider:,
      token:,
    }
      .merge(additional_config)
      .compact_blank!

    # Disable validation to avoid ping!
    Setting.set('ai_provider_config', config, validate: false)

    # Enable the provider after setting the configuration to ensure validation passes.
    Setting.set('ai_provider', true)
  end

  def unset_ai_provider
    Setting.set('ai_provider', false)
    Setting.set('ai_provider_config', {})
  end
end

RSpec.configure do |config|
  config.include AIProviderHelper
end
