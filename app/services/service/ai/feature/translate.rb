# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Translates given content into one target locale. Knows nothing about the object the content
# belongs to - the caller passes it as `object`, so the translation is stored per object and
# target locale.
class Service::AI::Feature::Translate < Service::AI::Feature

  def self.identifier
    Service::ContentTranslation::StoredTranslation::IDENTIFIER
  end

  def self.lookup_attributes(context_data, locale)
    Service::ContentTranslation::StoredTranslation.lookup_attributes(context_data[:object], locale)
  end

  def self.lookup_version(context_data, _locale)
    Service::ContentTranslation::StoredTranslation.version(context_data[:body], context_data[:html], context_data[:backend])
  end

  def persistable?
    true
  end

  def analytics?
    true
  end

  # Model output is sanitized nowhere else, and a translation never passes the sanitization
  # of the object it belongs to - so only HTML that sanitization allows may be stored.
  def post_transform_result(result)
    body = result.to_s
    body = HtmlSanitizer.strict(body) if html?

    # The sanitizer answers with its own message rather than raising when it gives up on the HTML.
    # Storing that would serve an English error sentence as the translation of this content until
    # the content itself changes.
    return if body == HtmlSanitizer::UNPROCESSABLE_HTML_MSG

    # Nothing usable came back, or sanitizing removed everything: store nothing instead of
    # serving an empty translation until the content changes.
    return if body.blank?

    body
  end

  private

  # Through the store rather than through the feature base: a backend without an AI feature writes
  # the same rows the same way.
  def save_result(result, ai_analytics_run:)
    Service::ContentTranslation::StoredTranslation.save(
      **store_key,
      translation:   result,
      metadata:      provider.metadata,
      analytics_run: ai_analytics_run,
    )
  end

  def store_key
    {
      object:  context_data[:object],
      locale:,
      content: context_data[:body],
      html:    context_data[:html],
      backend: context_data[:backend],
    }
  end

  def html?
    context_data[:html].present?
  end

  def options
    {
      temperature: 0.1,
    }
  end

  # The translation is the whole answer, like the writing assistant's text tools.
  def json_response?
    false
  end
end
