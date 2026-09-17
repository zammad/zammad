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

  def self.client(config)
    LibreTranslate::Client.new(url: config[:url], api_key: config[:api_key])
  end

  # Only the refused HTML format is not mapped here - #translate answers that one itself.
  def self.outcome_for(error)
    ERRORS.fetch(error.class, UnreachableError)
  end

  # @return [Hash, NilClass] `content`, `backend`, `fresh` and `analytics_run` - nil for the last
  #   one, there is no analytics run without an LLM. nil altogether without a translation.
  def execute
    stored = find_stored
    return result(stored.content, fresh: false) if stored
    return if persistence_strategy == :stored_only

    target_language # refuses a target the instance does not serve, before any content is sent

    translation = sanitize(translate)
    return if translation.nil?

    store(translation)

    result(translation, fresh: true)
  rescue LibreTranslate::Client::Error => e
    raise self.class.outcome_for(e)
  end

  private

  def translate
    return request(content, 'text') if !html

    begin
      request(content, 'html')
    rescue LibreTranslate::Client::HtmlFormatUnsupportedError
      # An instance too old for the HTML format answers in plain text, whose line breaks have to
      # survive as markup - the translation replaces the body of an HTML article.
      request(content.html2text(link_style: :plain), 'text').text2html
    end
  end

  def request(text, format)
    client.translate(text:, target: target_language, format:)
  end

  def target_language
    @target_language ||= candidate_languages.find { |code| supported_languages.include?(code) } ||
                         raise(UnsupportedLanguageError, format(__('The translation service does not support the target language %s.'), locale.locale))
  end

  def candidate_languages
    LANGUAGE_CODES[locale.locale] || [locale.locale.split('-').first]
  end

  def supported_languages
    client.languages
  end

  def client
    @client ||= self.class.client(config)
  end
end
