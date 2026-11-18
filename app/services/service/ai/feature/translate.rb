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

  # The same digest as an SQL expression, for looking up the translations of many objects in one
  # query. Kept next to the Ruby version so the two cannot drift apart - the parts have to be
  # concatenated in the order Service::ContentTranslation::StoredTranslation.version uses.
  #
  # @param backend [String, NilClass] `backend_name` of the service asking
  # @param html_sql [String] a boolean SQL expression telling whether the content is HTML
  # @param body_sql [String] the SQL expression of the content
  # @return [String]
  def self.lookup_version_sql(backend, html_sql, body_sql)
    backend_sql = ActiveRecord::Base.connection.quote(backend)

    html_format_sql = ActiveRecord::Base.connection.quote(Service::ContentTranslation::StoredTranslation.content_format(true, backend))
    text_format_sql = ActiveRecord::Base.connection.quote(Service::ContentTranslation::StoredTranslation.content_format(false, backend))

    "encode(sha256(convert_to(concat(#{backend_sql}, E'\\n', CASE WHEN #{html_sql} THEN #{html_format_sql} ELSE #{text_format_sql} END, E'\\n', #{body_sql}), 'UTF8')), 'hex')"
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
    body = document.translate(body) if document
    body = HtmlSanitizer.strict(body) if html? && body

    # The sanitizer answers with its own message rather than raising when it gives up on the HTML.
    # Storing that would serve an English error sentence as the translation of this content until
    # the content itself changes.
    return if body == HtmlSanitizer::UNPROCESSABLE_HTML_MSG

    # HTML without text comes back as it is, so without an extra text nothing was translated.
    return if html? && !document.content? && extra_translations.empty?

    # Nothing usable came back, or sanitizing removed everything: store nothing instead of
    # serving an empty translation until the content changes. Only where there is no content,
    # the extra texts are all there is to come back.
    return if body.blank? && (context_data[:body].present? || extra_translations.empty?)

    body.to_s
  end

  private

  # HTML without any text to translate, only an image or code for example, needs no request.
  def request_fresh
    return if html? && document.sections.empty?

    super
  end

  # The model gets HTML, and plain text with extra texts in front of it, as text with markers, see
  # ContentTranslation::Html and ContentTranslation::Text.
  def transform_user_prompt(prompt)
    document ? document.to_s : prompt
  end

  def document
    return @document if defined?(@document)

    @document = if html?
                  ContentTranslation::Html.new(context_data[:body], texts: extra_texts)
                elsif extra_texts.present?
                  ContentTranslation::Text.new(context_data[:body], texts: extra_texts)
                end
  end

  # Plain texts translated along with the content, in the same request.
  def extra_texts
    context_data[:extra_texts].to_h
  end

  def extra_translations
    document ? document.translated_texts.compact_blank : {}
  end

  # Through the store rather than through the feature base: a backend without an AI feature writes
  # the same rows the same way.
  def save_result(result, ai_analytics_run:)
    Service::ContentTranslation::StoredTranslation.save(
      **store_key,
      translation:        result,
      extra_texts:,
      extra_translations:,
      metadata:           provider.metadata,
      analytics_run:      ai_analytics_run,
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
