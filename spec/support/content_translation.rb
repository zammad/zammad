# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ContentTranslationHelper
  CONFIG_SETTINGS = %w[content_translation_deepl_config content_translation_libre_translate_config].freeze

  # Switches content translation on: stores the provider's config, names it as the active provider
  # and enables the article feature. Each one validates against the one before, hence the order.
  def setup_content_translation(provider: 'ai', ticket_article: true, **config)
    config_setting = Service::ContentTranslation::Backend.by_name(provider)&.config_setting_name
    Setting.set(config_setting, config.stringify_keys) if config_setting

    Setting.set('content_translation_provider', provider)
    Setting.set('content_translation_service', true)
    Setting.set('content_translation_ticket_article', ticket_article)
  end

  # Stores what another process would have stored: the settings cache of this one has not seen it.
  def store_setting_behind_cache(name, value)
    Setting.get(name)
    Setting.find_by(name:).update_columns(state_current: { value: }, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def unset_content_translation
    Setting.set('content_translation_service', false)
    Setting.set('content_translation_provider', '')
    CONFIG_SETTINGS.each { |name| Setting.set(name, {}) }
    Setting.set('content_translation_ticket_article', false)
  end
end

RSpec.configure do |config|
  config.include ContentTranslationHelper
end
