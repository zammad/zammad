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
  def store(translation)
    Service::ContentTranslation::StoredTranslation.save(**store_key, translation:)
  end

  def store_key
    { object:, locale:, content:, html:, backend: backend_name }
  end

  def result(translation, fresh:)
    { content: translation, backend: backend_name, fresh:, analytics_run: nil }
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
