# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ContentTranslationHelper
  # Switches content translation on: names the translation service and enables the article feature.
  # The service is named before the flag is set, because the flag validates against it.
  def setup_content_translation(provider: 'ai', ticket_article: true)
    Setting.set('content_translation_service_config', { 'provider' => provider })
    Setting.set('content_translation_service', true)
    Setting.set('content_translation_ticket_article', ticket_article)
  end

  def unset_content_translation
    Setting.set('content_translation_service', false)
    Setting.set('content_translation_service_config', {})
    Setting.set('content_translation_ticket_article', false)
  end
end

RSpec.configure do |config|
  config.include ContentTranslationHelper
end
