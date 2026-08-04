# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module AIProviderHelper
  # Sets up the `default` AI::ProviderConnection and enables the global AI provider switch.
  def setup_ai_provider(provider = 'zammad_ai', token: nil, **additional_config)
    config = { token: }
      .merge(additional_config)
      .compact_blank!

    AI::ProviderConnection
      .find_or_initialize_by(name: 'default')
      .update!(provider:, config:, default_chat: true)

    Setting.set('ai_provider', true)
  end

  def unset_ai_provider
    Setting.set('ai_provider', false)
    AI::ProviderConnection.find_by(name: 'default')&.destroy
  end

  # Config of the `default` connection, as the provider adapters receive it.
  def default_ai_provider_config
    AI::ProviderConnection.find_by(name: 'default')&.config&.deep_symbolize_keys || {}
  end

  # Merges the given values into the `default` connection's config.
  def update_ai_provider_config(values)
    connection = AI::ProviderConnection.find_by(name: 'default')
    connection.update!(config: connection.config.merge(values.deep_stringify_keys))
  end

  # Routes a feature identifier to a connection, creating or refreshing the connection on demand.
  def setup_ai_feature_routing(identifier, provider: 'open_ai', connection_name: 'default', **config)
    connection = AI::ProviderConnection.find_or_initialize_by(name: connection_name)
    connection.update!(provider:, config: { token: 'secret-token' }.merge(config))

    AI::FeatureProvider.create!(identifier: identifier.to_s, provider_connection: connection)
  end

  def set_ai_provider_default_embedding(default_embedding: true)
    connection = AI::ProviderConnection.find_by(name: 'default')
    connection.update!(default_embedding: default_embedding)
  end

  def set_ai_provider_default_ocr(default_ocr: true)
    connection = AI::ProviderConnection.find_by(name: 'default')
    connection.update!(default_ocr:)
  end
end

RSpec.configure do |config|
  config.include AIProviderHelper
end
