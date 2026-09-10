# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Translates given content into one target locale. Knows nothing about the object the content
# belongs to - the caller passes it as `object`, so the translation is stored per object and
# target locale.
class Service::AI::Feature::Translate < Service::AI::Feature
  def self.identifier
    'translate'
  end

  def self.lookup_attributes(context_data, locale)
    {
      identifier:,
      locale:,
      related_object: context_data[:object],
    }
  end

  # A content digest instead of a timestamp, because an object can be touched without its content
  # changing. Deliberately no producing service in the version: a translation of the same content
  # is reused whichever service made it, so switching the configured service costs nothing. Which
  # service made it is stored with the result instead.
  def self.lookup_version(context_data, _locale)
    Digest::SHA256.hexdigest("#{context_data[:html]}\n#{context_data[:body]}")
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

  # A stored translation is reused across services, so the caller has to be able to tell which one
  # actually made it - and that is not the content, it is how the content came about.
  def result_metadata
    { 'backend' => context_data[:backend] }
  end

  private

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
