# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The HTTP side of a LibreTranslate instance: its endpoints, its API key, and what its refusals
# mean. A caller gets a translation or one of the errors below, never a response to interpret.
class LibreTranslate::Client
  class Error < StandardError; end
  class UnreachableError < Error; end
  class InvalidCredentialsError < Error; end
  class UnsupportedLanguageError < Error; end
  class QuotaExceededError < Error; end
  class ContentTooLargeError < Error; end

  # LibreTranslate gained the HTML format only in a later release, so an instance may refuse it.
  # Its own error, because the same content can be sent again as plain text.
  class HtmlFormatUnsupportedError < Error; end

  # An admin installs a model and the instance serves a new language at once, so a longer cache
  # would keep refusing one that already works.
  LANGUAGES_CACHE_TTL = 5.minutes

  HTML_FORMAT_REFUSED = %r{format is not supported}i

  # An instance without a model for the language, and one without a path from the detected source.
  UNSUPPORTED_LANGUAGE = %r{is not supported|is not available as target}i

  TEXT_LIMIT_EXCEEDED = %r{exceeds text limit}i

  # Shares its status with a refused API key, so only the wording separates the two.
  RATE_LIMIT_BAN = %r{too many request limits violations}i

  # Named after the feature: that is what an admin looks for in the HTTP log.
  LOG_FACILITY = 'content_translation'.freeze

  attr_reader :url, :api_key

  def initialize(url:, api_key: nil)
    @url     = url.to_s.delete_suffix('/')
    @api_key = api_key
  end

  # Sent without the API key: LibreTranslate exempts this endpoint from its key check.
  #
  # @param force [Boolean] ask the instance although the list is cached
  # @return [Array<String>] the language codes
  def languages(force: false)
    Rails.cache.fetch("#{self.class.name}/languages/#{url}", expires_in: LANGUAGES_CACHE_TTL, force:) do
      response = request { UserAgent.get("#{url}/languages", {}, request_options) }
      raise_for(response) if !response.success?

      # Raising keeps an answer that names no language out of the cache, which would refuse all of
      # them until it expired.
      Array.wrap(response.data).filter_map { |language| language['code'] }.presence || raise(UnreachableError)
    end
  end

  # @param format [String] 'text' or 'html'; an instance too old for the latter raises
  #   HtmlFormatUnsupportedError
  # @return [String] the translated text
  def translate(text:, target:, format:)
    body = { q: text, source: 'auto', target:, format: }
    body[:api_key] = api_key if api_key.present?

    response = request { UserAgent.post("#{url}/translate", body, request_options) }
    raise_for(response) if !response.success?

    # A URL pointing at something else than a LibreTranslate instance can answer 200 without one.
    translated = response.data['translatedText'] if response.data.is_a?(Hash)
    raise UnreachableError if !translated.is_a?(String)

    translated
  end

  private

  # UserAgent builds the request before its own error handling, so a URL Ruby cannot parse would
  # leave the errors above as an exception of its own.
  def request
    yield
  rescue URI::Error, ArgumentError
    raise UnreachableError
  end

  # The instance's own wording stays in the HTTP log; the caller gets an error it can act on.
  def raise_for(response)
    # UserAgent fills .data on a successful answer only, so a refusal is read from the raw body.
    raise error_class(response.code.to_i, response.body.to_s)
  end

  def error_class(code, message)
    # A transport failure never reaches a status code; UserAgent reports it as 0.
    return UnreachableError        if code.zero? || code >= 500
    return QuotaExceededError      if code == 429 || message.match?(RATE_LIMIT_BAN)
    return InvalidCredentialsError if code.in?([401, 403])
    return ContentTooLargeError    if code == 413 || message.match?(TEXT_LIMIT_EXCEEDED)

    # Before the language: a refused HTML format shares its wording with an unsupported one.
    return HtmlFormatUnsupportedError if code == 400 && message.match?(HTML_FORMAT_REFUSED)
    return UnsupportedLanguageError   if message.match?(UNSUPPORTED_LANGUAGE)

    # Nothing may escape these errors, so an answer none of them describes counts as unusable.
    UnreachableError
  end

  def request_options
    {
      verify_ssl: true,
      json:       true,
      log:        { facility: LOG_FACILITY },
    }
  end
end
