# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::ContentTranslation::Backend::Concerns::StoresTranslations
  extend ActiveSupport::Concern

  private

  def find_stored
    return if persistence_strategy == :request_only
    # A regeneration asks for another translation of what is stored, so the store must not answer.
    return if regeneration_of

    Service::ContentTranslation::StoredTranslation.find(**store_key)
  end

  # .save answers with nothing when it loses the race for the row; this one has its own translation.
  def store(translation, analytics_run:)
    Service::ContentTranslation::StoredTranslation.save(**store_key, translation:, analytics_run:)
  end

  def store_key
    { object:, locale:, content:, html:, backend: backend_name }
  end

  # The entry a rating of this translation attaches to, keyed like the stored row so a backend
  # without an AI feature records what the AI one records for free. It names no triggering object
  # on purpose: the AI agent satisfaction figures are scoped by that, and this is no AI answer.
  def save_analytics_run(translation)
    AI::Analytics::Run.create!(
      **Service::ContentTranslation::StoredTranslation.lookup_attributes(object, locale),
      version:         Service::ContentTranslation::StoredTranslation.version(content, html, backend_name),
      content:         translation,
      ai_service_name: backend_name,
      regeneration_of:,
    )
  end

  def result(translation, fresh:, analytics_run:)
    { content: translation, backend: backend_name, fresh:, analytics_run: }
  end

  def config
    @config ||= Setting.get('content_translation_service_config').to_h.with_indifferent_access
  end

  # Nothing else sanitizes what the service answers, and a translation never passes the
  # sanitization of the object it belongs to - so only HTML that sanitization allows may be stored.
  def sanitize(translation)
    body = html ? HtmlSanitizer.strict(translation) : translation

    # The sanitizer answers with its own message rather than raising when it gives up on the HTML;
    # storing that would serve an English error sentence as this content's translation.
    return if body == HtmlSanitizer::UNPROCESSABLE_HTML_MSG

    # The row is keyed by the content, so an empty translation would be served until it changes.
    return if body.blank?

    body
  end
end
