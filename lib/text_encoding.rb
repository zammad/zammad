# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rchardet'
require 'mail'

# Transcodes a string to UTF-8, based on a declared charset, the encoding of the
# string itself, or - as a last resort - an auto-detected one.
class TextEncoding

  # ASCII-8BIT carries no encoding information, and UTF-8 has been ruled out
  # before the viable encodings are considered.
  NON_VIABLE_ENCODINGS = [Encoding::ASCII_8BIT, Encoding::UTF_8].freeze

  # GB2312 and GBK are subsets of GB18030. Like the `mail` gem, read them as
  # GB18030: Outlook declares code page 936 (GBK) as 'gb2312', and text declared
  # as GBK may carry four-byte sequences, both of which Ruby's strict GB2312 and
  # GBK reject.
  GB18030_SUBSETS = [Encoding::GB2312, Encoding::GBK].freeze

  GB18030_EURO_SIGN = '€'.encode(Encoding::GB18030).freeze

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

  # Convert the string from the given charset, if it decodes the string.
  def encoded_from_given_charset
    return if options[:from].blank?

    encoding = find_encoding(options[:from])
    decoded  = decode(encoding)
    return decoded if encoding != Encoding::GB18030

    # GB18030 maps the byte pairs that GBK leaves undefined to private use, and
    # Big5 keeps its most common characters there. Mislabelled Big5 goes to the
    # detection instead of decoding as wrong characters.
    decoded if !decoded&.match?(%r{\p{Co}})
  rescue ArgumentError, EncodingError => e
    Rails.logger.error { e.inspect }
    nil
  end

  def encoded_from_viable_encodings
    viable_encodings.each do |encoding|
      decoded = decode(encoding)
      return decoded if decoded
    rescue EncodingError => e
      Rails.logger.error { e.inspect }
    end

    nil
  end

  # Returns the string decoded from the given encoding, or nil if it is invalid in it.
  def decode(encoding)
    candidate = string.dup.force_encoding(encoding)
    candidate = read_cp936_euro_signs(candidate) if encoding == Encoding::GB18030
    return if !candidate&.valid_encoding?

    candidate.encode('utf-8')
  end

  # GB18030 rejects the single byte that code page 936 uses for the euro sign.
  # Like the `mail` gem and the WHATWG gb18030 decoder, read it as '€'. Any other
  # invalid sequence means the string is not GB18030.
  def read_cp936_euro_signs(gb18030)
    return gb18030 if gb18030.valid_encoding?

    gb18030.scrub do |bytes|
      break if bytes.bytesize != 1 || bytes.getbyte(0) != 0x80

      GB18030_EURO_SIGN
    end
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

  # Resolves a charset label to the `Encoding` that decodes it.
  def find_encoding(charset)
    encoding = resolve_encoding(charset)
    return Encoding::GB18030 if GB18030_SUBSETS.include?(encoding)

    encoding
  end

  # Ruby knows only a subset of the charset labels that occur in real mail. For
  # labels it cannot resolve, the `mail` gem's alias table is consulted before
  # giving up, so that a declared charset is not silently dropped in favour of
  # charset detection (e.g. 'ks_c_5601-1987', the Microsoft alias for CP949).
  def resolve_encoding(charset)
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
