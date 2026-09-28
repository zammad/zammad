# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rchardet'
require 'mail'

# Transcodes a string to UTF-8, based on a declared charset, the encoding of the
# string itself, or - as a last resort - an auto-detected one.
class TextEncoding

  # ASCII-8BIT carries no encoding information, and UTF-8 has been ruled out
  # before the viable encodings are considered.
  NON_VIABLE_ENCODINGS = [Encoding::ASCII_8BIT, Encoding::UTF_8].freeze

=begin

Returns a copy of the given string, encoded in UTF-8. Anything that is not a
String is coerced with `to_s` first.

  TextEncoding.utf8_encode(string, from: 'ks_c_5601-1987', fallback: :read_as_sanitized_binary)

Options:

  * from: A charset to try first. Takes precedence over the current and
          auto-detected encodings.

  * fallback: The strategy to follow if no valid encoding can be found.
    * `:output_to_binary` returns an ASCII-8BIT-encoded string.
    * `:read_as_sanitized_binary` returns a UTF-8-encoded string with all
      invalid byte sequences replaced with "?" characters.

Raises `EncodingError` if no valid encoding was found and no fallback was given.

=end

  def self.utf8_encode(value, **)
    new(value, **).utf8_encode
  end

  def initialize(value, **options)
    # Work on a copy, so that the caller's string is never modified.
    @string  = value.to_s.dup
    @options = options
  end

  def utf8_encode
    return string.force_encoding('utf-8') if string.dup.force_encoding('utf-8').valid_encoding?

    encoded_from_given_charset || encoded_from_viable_encodings || fallback
  end

  private

  attr_reader :string, :options

  # Convert the string to the given charset, if valid_encoding? is true.
  def encoded_from_given_charset
    return if options[:from].blank?

    encoding = find_encoding(options[:from])
    return if encoding.blank? || !string.dup.force_encoding(encoding).valid_encoding?

    string.force_encoding(encoding)
    string.encode!('utf-8', encoding)
  rescue ArgumentError, EncodingError => e
    Rails.logger.error { e.inspect }
    nil
  end

  def encoded_from_viable_encodings
    viable_encodings.each do |encoding|

      return string.encode!('utf-8', encoding)
    rescue EncodingError => e
      Rails.logger.error { e.inspect }

    end

    nil
  end

  def fallback
    case options[:fallback]
    when :output_to_binary
      string.force_encoding('ascii-8bit')
    when :read_as_sanitized_binary
      string.encode!('utf-8', 'ascii-8bit', invalid: :replace, undef: :replace, replace: '?')
    else
      raise EncodingError, 'could not find a valid input encoding'
    end
  end

  # Resolves a charset label to an `Encoding`.
  #
  # Ruby knows only a subset of the charset labels that occur in real mail. For
  # labels it cannot resolve, the `mail` gem's alias table is consulted before
  # giving up, so that a declared charset is not silently dropped in favour of
  # charset detection (e.g. 'ks_c_5601-1987', the Microsoft alias for CP949).
  def find_encoding(charset)
    Encoding.find(charset)
  rescue ArgumentError
    picked = Mail::Utilities.pick_encoding(charset)

    # The gem falls back to BINARY for labels it does not know either.
    raise if picked == Encoding::BINARY

    picked
  end

  def viable_encodings
    [string.encoding, detected_encoding]
      .compact
      .reject { NON_VIABLE_ENCODINGS.include?(it) }
      .select { string.dup.force_encoding(it).valid_encoding? }
  end

  # CharDet reports labels that Ruby cannot resolve ('HZ-GB-2312', 'x-euc-tw').
  # Dropping such a label leaves the configured fallback to deal with the string,
  # instead of raising out of `utf8_encode`.
  def detected_encoding
    charset = CharDet.detect(string)['encoding']

    Encoding.find(charset) if charset.present?
  rescue ArgumentError
    nil
  end
end
