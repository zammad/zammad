# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Translation through a LibreTranslate instance. The first backend without an AI feature behind it,
# so the HTML handling and the store are its own rather than the feature layer's; the instance
# itself is reached through LibreTranslate::Client.
class Service::ContentTranslation::Backend::LibreTranslate < Service::ContentTranslation::Backend::Base
  include Service::ContentTranslation::Backend::Concerns::StoresTranslations

  # Zammad locales LibreTranslate does not name by their primary subtag. The first code an instance
  # serves wins - Portuguese may fall back on the other region, Chinese not on the other script.
  LANGUAGE_CODES = {
    'no-no' => %w[nb],
    'pt-br' => %w[pb pt],
    'zh-tw' => %w[zt],
  }.freeze

  # A caller acts on the outcomes of a backend, not on the error family the client has of its own.
  ERRORS = {
    LibreTranslate::Client::UnreachableError         => UnreachableError,
    LibreTranslate::Client::InvalidCredentialsError  => InvalidCredentialsError,
    LibreTranslate::Client::UnsupportedLanguageError => UnsupportedLanguageError,
    LibreTranslate::Client::QuotaExceededError       => QuotaExceededError,
    LibreTranslate::Client::ContentTooLargeError     => ContentTooLargeError,
  }.freeze

  CLIENT_ERROR       = LibreTranslate::Client::Error
  HTML_REFUSED_ERROR = LibreTranslate::Client::HtmlFormatUnsupportedError

  # What the connection test asks to be translated. Short enough to cost the instance nothing,
  # and its outcome is never read - only whether the instance accepted the request.
  PING_CONTENT = 'Hello'.freeze

  # Stored with every translation, so a class rename must not change it.
  def self.backend_name
    'libre_translate'
  end

  # The server URL alone; an instance that requires no authentication needs no `api_key`.
  def self.required_config_keys
    %w[url]
  end

  def self.config_setting_name
    'content_translation_libre_translate_config'
  end

  # The language listing proves the instance answers, but it is exempt from the key check - so only
  # a translation proves a configured key, and that an instance demanding one has got it.
  def self.ping!(config)
    client    = client(config)
    languages = client.languages(force: true)

    begin
      client.translate(text: PING_CONTENT, target: languages.first, format: 'text')
    rescue LibreTranslate::Client::InvalidCredentialsError, LibreTranslate::Client::UnreachableError
      raise
    rescue LibreTranslate::Client::Error
      # A refused key and an endpoint that did not answer say something about this configuration:
      # any other refusal - a rate limit, or the language pair the probe picked itself - still
      # proves the instance took the request.
      nil
    end
  rescue LibreTranslate::Client::Error => e
    raise outcome_for(e)
  end

  # The instance names what it serves; a locale it could not be asked for is not offered.
  def self.supported_locales(locales)
    languages = client(config).languages

    locales.select { |locale| candidate_languages(locale).intersect?(languages) }
  rescue LibreTranslate::Client::Error => e
    raise outcome_for(e)
  end

  def self.candidate_languages(locale)
    LANGUAGE_CODES[locale.locale] || [locale.locale.split('-').first]
  end

  def self.client(config)
    LibreTranslate::Client.new(url: config[:url], api_key: config[:api_key])
  end

  private

  # LibreTranslate unescapes its HTML answer itself (since v1.2.7), so the extra texts arrive as text.
  def extra_text_from_html(translation)
    translation
  end

  # A single text is sent as a string: only several need the list form.
  def request(texts, html:)
    Array(client.translate(text: texts.one? ? texts.first : texts, target: target_language, format: html ? 'html' : 'text'))
  end

  def target_language
    @target_language ||= candidate_languages.find { |code| supported_languages.include?(code) } ||
                         raise(UnsupportedLanguageError, format(__('The translation service does not support the target language %s.'), locale.locale))
  end

  def candidate_languages
    self.class.candidate_languages(locale)
  end

  def supported_languages
    client.languages
  end
end
