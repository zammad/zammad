# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class DeepL::Client
  attr_reader :tier, :api_key

  class Error < StandardError; end
  class UnreachableError < Error; end
  class InvalidCredentialsError < Error; end
  class UnsupportedLanguageError < Error; end
  class QuotaExceededError < Error; end
  class ContentTooLargeError < Error; end

  class HtmlRefusedError < Error; end

  BASE_URLS = {
    'free' => 'https://api-free.deepl.com',
    'pro'  => 'https://api.deepl.com',
  }.freeze

  LOG_FACILITY = 'content_translation'.freeze

  # DeepL names the parameter it refused, and the target language is the only one a caller can act
  # on. The backend keeps an unsupported target off the request path, so this catches one DeepL
  # dropped since.
  UNSUPPORTED_LANGUAGE = %r{target_lang}i

  def initialize(tier:, api_key:)
    @tier    = tier
    @api_key = api_key
  end

  # @param html [Boolean] whether DeepL has to keep the markup of the content; it raises
  #   HtmlRefusedError for content it will not take that way
  # @return [String] the translated text
  def translate(text:, target:, html: false)
    body = { text: [text], target_lang: target }
    body[:tag_handling] = 'html' if html

    response = UserAgent.post("#{base_url}/v2/translate", body, request_options)
    raise_for(response, html:) if !response.success?

    # An answer that carries no translation must not reach a caller as one.
    translations = response.data['translations'] if response.data.is_a?(Hash)
    translated   = translations.first['text'] if translations.is_a?(Array) && translations.first.is_a?(Hash)
    raise UnreachableError if !translated.is_a?(String)

    translated
  end

  private

  def base_url
    BASE_URLS[tier.to_s] || raise(UnreachableError)
  end

  # DeepL's own wording stays in the HTTP log; the caller gets an error it can act on.
  def raise_for(response, html:)
    raise error_class(response.code.to_i, response.body.to_s, html)
  end

  def error_class(code, message, html)
    # Before the server error range: DeepL answers 529 with the wording of 429, so a rate limit
    # reaches above 500 too and would otherwise be reported as an outage.
    return QuotaExceededError      if code.in?([429, 456, 529])
    # A transport failure never reaches a status code; UserAgent reports it as 0.
    return UnreachableError        if code.zero? || code >= 500
    return InvalidCredentialsError if code == 403
    return ContentTooLargeError    if code == 413

    if code == 400
      return UnsupportedLanguageError if message.match?(UNSUPPORTED_LANGUAGE)

      return HtmlRefusedError if html
    end

    # Nothing may escape these errors, so an answer none of them describes counts as unusable.
    UnreachableError
  end

  def request_options
    {
      verify_ssl: true,
      json:       true,
      headers:    { 'Authorization' => "DeepL-Auth-Key #{api_key}" },
      log:        { facility: LOG_FACILITY },
    }
  end
end
