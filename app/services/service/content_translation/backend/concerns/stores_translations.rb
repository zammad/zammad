# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A backend calling a translation service of its own. It names the client's error family
# (CLIENT_ERROR, mapped by ERRORS) and the error of refused markup (HTML_REFUSED_ERROR), and
# answers .client(config), #request and #target_language.
module Service::ContentTranslation::Backend::Concerns::StoresTranslations
  extend ActiveSupport::Concern

  class_methods do
    # Only the refused markup is not mapped here - #translate answers that one itself.
    def outcome_for(error)
      self::ERRORS.fetch(error.class, self::UnreachableError)
    end
  end

  # @return [Hash, NilClass] `content`, `extra_texts`, `backend`, `fresh` and `analytics_run`; nil
  #   altogether without a translation.
  def execute
    stored = find_stored
    return stored_result(stored) if stored
    return if persistence_strategy == :stored_only

    target_language # refuses a target the service does not serve, before any content is sent

    translation, extra_translations = usable_translations
    return if translation.nil?

    analytics_run = save_analytics_run(translation)

    store(translation, extra_translations, analytics_run:)

    result(translation, extra_translations, fresh: true, analytics_run:)
  rescue self.class::CLIENT_ERROR => e
    raise self.class.outcome_for(e)
  end

  private

  def find_stored
    return if persistence_strategy == :request_only
    # A regeneration asks for another translation of what is stored, so the store must not answer.
    return if regeneration_of

    Service::ContentTranslation::StoredTranslation.find(**store_key)
  end

  def stored_result(stored)
    result(
      stored.content,
      Service::ContentTranslation::StoredTranslation.extra_translations(stored, extra_texts),
      fresh:         false,
      analytics_run: stored.ai_analytics_run,
    )
  end

  # .save answers with nothing when it loses the race for the row; this one has its own translation.
  def store(translation, extra_translations, analytics_run:)
    Service::ContentTranslation::StoredTranslation.save(**store_key, translation:, extra_texts:, extra_translations:, analytics_run:)
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

  def result(translation, extra_translations, fresh:, analytics_run:)
    { content: translation, extra_texts: extra_translations, backend: backend_name, fresh:, analytics_run: }
  end

  def config
    @config ||= self.class.config
  end

  def client
    @client ||= self.class.client(config)
  end

  def translate
    return translate_texts(content, html: false) if !html

    begin
      translate_texts(content, html: true)
    rescue self.class::HTML_REFUSED_ERROR
      # The service would not take this content as markup and answers in plain text, whose line
      # breaks have to survive as markup - the translation replaces the body of an HTML article.
      translation, extra_translations = translate_texts(content.html2text(link_style: :plain), html: false)

      [translation&.text2html, extra_translations]
    end
  end

  # The content and the extra texts in one request of the including backend, which answers
  # #request(texts, html:) with one translation per text. The extra texts are plain text: an HTML
  # request takes them escaped, and its answer is turned back into text.
  #
  # @param text [String] the content as it is sent, which may differ from the content itself
  # @return [Array(String, Hash{Symbol => String})] the translated content, nil without content,
  #   and the translated extra texts
  def translate_texts(text, html:)
    texts = extra_texts.values
    texts = texts.map { |extra_text| ERB::Util.html_escape(extra_text) } if html
    texts.unshift(text) if text.present?
    return [nil, {}] if texts.empty?

    translations = request(texts, html:)
    translation  = translations.shift if text.present?
    translations = translations.map { |extra_translation| extra_text_from_html(extra_translation) } if html

    [translation, extra_texts.keys.zip(translations.map(&:strip)).to_h.compact_blank]
  end

  # An HTML answer keeps the extra texts escaped. A backend whose service unescapes it itself
  # takes the answer as it is, as decoding it again would turn literal entities into characters.
  def extra_text_from_html(translation)
    Loofah.html5_fragment(translation).text(encode_special_chars: false)
  end

  # What may be stored of #translate. Content whose translation is not usable fails all of it;
  # an object without content is translated for its extra texts alone.
  #
  # @return [Array(String, Hash{Symbol => String}), NilClass]
  def usable_translations
    translation, extra_translations = translate

    if content.present?
      translation = sanitize(translation.to_s)
      return if translation.nil?
    elsif extra_translations.empty?
      return
    end

    [translation.to_s, extra_translations]
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
