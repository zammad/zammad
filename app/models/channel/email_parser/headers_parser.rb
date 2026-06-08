# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailParser::HeadersParser
  attr_reader :mail

  def initialize(mail)
    @mail = mail
  end

  def message_header_hash
    [imported_fields, raw_fields, custom_fields].reduce({}.with_indifferent_access, &:merge)
  end

  private

  def imported_fields
    @imported_fields ||= mail.header.fields.to_h do |f|
      value = parse_single_imported_field(f)

      [f.name.downcase, value]
    end
  end

  def parse_single_imported_field(field)
    if field.value.match?(ISO2022JP_REGEXP)
      header_field_unpack_japanese(field)
    else
      field.decoded.to_utf8
    end
  # fields that cannot be cleanly parsed fallback to the empty string
  rescue Mail::Field::IncompleteParseError
    ''
  rescue Encoding::CompatibilityError => e
    try_iso88591 = field.value.force_encoding('iso-8859-1').encode('utf-8')

    raise e if !try_iso88591.is_utf8?

    field.value = try_iso88591
    field.decoded.to_utf8
  rescue Date::Error => e
    raise e if field.name != 'Resent-Date'

    field.value = ''

    nil
  rescue
    field.decoded.to_utf8(fallback: :read_as_sanitized_binary)
  end

  def raw_fields
    @raw_fields ||= mail
      .header
      .fields
      .index_by { |f| "raw-#{f.name.downcase}" }
  end

  def custom_fields
    @custom_fields ||= build_custom_fields
  end

  def build_custom_fields
    hash = {}

    hash.replace(imported_fields.slice(*Channel::EmailParser::RECIPIENT_FIELDS)
                             .transform_values { |v| v.match?(Channel::EmailParser::EMAIL_REGEX) ? v : '' })

    hash['x-any-recipient'] = hash.values.compact_blank.join(', ')
    hash['message_id']      = imported_fields['message-id']
    hash['subject']         = imported_fields['subject']&.strip
    hash['date']            = begin
      Time.zone.parse(mail.date.to_s)
    rescue
      nil
    end

    hash
  end

  ISO2022JP_REGEXP = %r{=\?ISO-2022-JP\?B\?(.+?)\?=}

  # https://github.com/zammad/zammad/issues/3115
  def header_field_unpack_japanese(field)
    field.value.gsub ISO2022JP_REGEXP do
      Channel::EmailParser::Encoding.force_japanese_encoding Base64.decode64($1)
    end
  end
end

module Mail

  # workaround to get content of no parseable headers - in most cases with non 7 bit ascii signs
  class Field
    def raw_value
      begin
        value = @raw_value.try(:utf8_encode)
      rescue
        value = @raw_value.utf8_encode(fallback: :read_as_sanitized_binary)
      end
      return value if value.blank?

      value.sub(%r{^.+?:(\s|)}, '')
    end
  end

  # issue#348 - IMAP mail fetching stops because of broken spam email (e. g. broken Content-Transfer-Encoding value see test/fixtures/mail43.box)
  # https://github.com/zammad/zammad/issues/348
  class Body
    def decoded
      if Encodings.defined?(encoding)
        Encodings.get_encoding(encoding).decode(raw_source)
      else
        Rails.logger.info "UnknownEncodingType: Don't know how to decode #{encoding}!"
        raw_source
      end
    end
  end
end
