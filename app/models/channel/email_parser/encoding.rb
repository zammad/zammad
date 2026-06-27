# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailParser::Encoding
  JAPANESE_ENCODINGS = %w[ISO-2022-JP ISO-2022-JP-KDDI SJIS].freeze

  def self.force_parts_encoding_if_needed(mail)
    # enforce encoding on both multipart parts and main body
    ([mail] + mail.all_parts).each { |elem| force_single_part_encoding_if_needed(elem) }
  end

  # https://github.com/zammad/zammad/issues/6144
  def self.force_single_part_encoding_if_needed(part)
    return if part.attachment?
    return if part.content_type.blank? || !part.content_type.start_with?('text')
    return if part.charset.present? && part.charset.downcase != 'iso-2022-jp'

    new_body  = force_japanese_encoding part.body.encoded.unpack1('M')
    part.body = new_body if new_body.present?
  end

  # https://github.com/zammad/zammad/issues/3096
  # specific email needs to be forced to ISO-2022-JP
  # but that breaks other emails that can be forced to SJIS only
  # thus force to ISO-2022-JP but fallback to SJIS
  #
  # https://github.com/zammad/zammad/issues/3368
  # some characters are not included in the official ISO-2022-JP
  # ISO-2022-JP-KDDI superset provides support for more characters
  def self.force_japanese_encoding(input)
    JAPANESE_ENCODINGS
      .lazy
      .map { |encoding| try_encoding(input, encoding) }
      .detect(&:present?)
  end

  def self.try_encoding(input, encoding)
    input.force_encoding(encoding).encode('UTF-8')
  rescue
    nil
  end
end
