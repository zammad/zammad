# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::ContentTranslation::Backend::DeepL < Service::ContentTranslation::Backend::Base
  include Service::ContentTranslation::Backend::Concerns::StoresTranslations

  LANGUAGE_CODES = {
    'ar'    => 'AR',
    'bg'    => 'BG',
    'bn'    => 'BN',
    'ca'    => 'CA',
    'cs'    => 'CS',
    'da'    => 'DA',
    'de-de' => 'DE',
    'el'    => 'EL',
    # DeepL serves no Canadian English; its spelling follows the British conventions.
    'en-ca' => 'EN-GB',
    'en-gb' => 'EN-GB',
    'en-us' => 'EN-US',
    'es-co' => 'ES-419',
    'es-es' => 'ES',
    'es-mx' => 'ES-419',
    'et'    => 'ET',
    'fa-ir' => 'FA',
    'fi'    => 'FI',
    'fr-ca' => 'FR-CA',
    'fr-fr' => 'FR',
    'he-il' => 'HE',
    'hi-in' => 'HI',
    'hr'    => 'HR',
    'hu'    => 'HU',
    'id'    => 'ID',
    'is'    => 'IS',
    'it-it' => 'IT',
    'ja'    => 'JA',
    'ko-kr' => 'KO',
    'lt'    => 'LT',
    'lv'    => 'LV',
    'ms-my' => 'MS',
    'nl-nl' => 'NL',
    'no-no' => 'NB',
    'pl'    => 'PL',
    'pt-br' => 'PT-BR',
    'pt-pt' => 'PT-PT',
    'ro-ro' => 'RO',
    'ru'    => 'RU',
    'sk'    => 'SK',
    'sl'    => 'SL',
    'sv-se' => 'SV',
    'th'    => 'TH',
    'tr'    => 'TR',
    'uk'    => 'UK',
    'vi'    => 'VI',
    'zh-cn' => 'ZH-HANS',
    'zh-tw' => 'ZH-HANT',
  }.freeze

  ERRORS = {
    DeepL::Client::UnreachableError         => UnreachableError,
    DeepL::Client::InvalidCredentialsError  => InvalidCredentialsError,
    DeepL::Client::UnsupportedLanguageError => UnsupportedLanguageError,
    DeepL::Client::QuotaExceededError       => QuotaExceededError,
    DeepL::Client::ContentTooLargeError     => ContentTooLargeError,
  }.freeze

  PING_CONTENT = 'Hello'.freeze
  PING_TARGET  = 'DE'.freeze

  def self.backend_name
    'deepl'
  end

  # DeepL has no unauthenticated mode, and the tier decides which host the key is sent to.
  def self.required_config_keys
    %w[api_key tier]
  end

  def self.ping!(config)
    client(config).translate(text: PING_CONTENT, target: PING_TARGET)
  rescue DeepL::Client::InvalidCredentialsError, DeepL::Client::UnreachableError => e
    raise outcome_for(e)
  rescue DeepL::Client::Error
    # Any other refusal - an exhausted quota, a rate limit - still proves DeepL took the key,
    # which is all this test asks.
    nil
  end

  def self.client(config)
    DeepL::Client.new(tier: config[:tier], api_key: config[:api_key])
  end

  # Only the refused markup is not mapped here - #translate answers that one itself.
  def self.outcome_for(error)
    ERRORS.fetch(error.class, UnreachableError)
  end

  # @return [Hash, NilClass] `content`, `backend`, `fresh` and `analytics_run`; nil altogether
  #   without a translation.
  def execute
    stored = find_stored
    return result(stored.content, fresh: false, analytics_run: stored.ai_analytics_run) if stored
    return if persistence_strategy == :stored_only

    target_language # refuses a target DeepL does not serve, before any content is sent

    translation = sanitize(translate)
    return if translation.nil?

    analytics_run = save_analytics_run(translation)

    store(translation, analytics_run:)

    result(translation, fresh: true, analytics_run:)
  rescue DeepL::Client::Error => e
    raise self.class.outcome_for(e)
  end

  private

  def translate
    return request(content, html: false) if !html

    begin
      request(content, html: true)
    rescue DeepL::Client::HtmlRefusedError
      # DeepL would not take this content as markup, and its answer is plain text whose line breaks
      # have to survive as markup - the translation replaces the body of an HTML article.
      request(content.html2text(link_style: :plain), html: false).text2html
    end
  end

  def request(text, html:)
    client.translate(text:, target: target_language, html:)
  end

  def target_language
    @target_language ||= LANGUAGE_CODES[locale.locale] ||
                         raise(UnsupportedLanguageError, format(__('The translation service does not support the target language %s.'), locale.locale))
  end

  def client
    @client ||= self.class.client(config)
  end
end
