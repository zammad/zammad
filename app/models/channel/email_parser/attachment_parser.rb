# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailParser::AttachmentParser
  attr_reader :part, :attachments

  def initialize(part, attachments)
    @part = part
    @attachments = attachments
  end

  def parse
    [{
      data:        file_body,
      filename:    filename,
      preferences: headers,
    }]
  end

  private

  def file_body
    @file_body ||= String.new(part.body.to_s)
  end

  def filename
    @filename ||= begin
      filename = filename_from_content.presence || filename_from_content_type_id.presence || 'file'

      filename_ensure_unique(filename, attachments)
    end
  end

  def headers
    @headers ||= parse_headers
  end

  def parse_headers
    headers = part.header.fields.each_with_object({}) do |field, memo|
      memo[field.name.to_s] = field.to_utf8.presence || field.raw_value
    rescue
      memo[field.name.to_s] = field.raw_value
    end

    headers = headers_add_additional_values(headers)

    # remove not needed header
    headers.delete('Content-Transfer-Encoding')
    headers.delete('Content-Disposition')

    headers
  end

  def headers_add_additional_values(headers)
    # cleanup content id, <> will be added automatically later
    if headers['Content-ID'].blank? && headers['Content-Id'].present?
      headers['Content-ID'] = headers['Content-Id']
    end

    headers['Content-ID']&.delete_prefix!('<')&.delete_suffix!('>')

    # get mime type
    if part.header[:content_type]&.string
      headers['Mime-Type'] = part.header[:content_type].string
    end

    # get charset
    if part.header&.charset
      headers['Charset'] = part.header.charset
    end

    headers
  end

  CONTENT_DISPOSTION_FILENAME_REGEXPS = [
    %r{(filename|name)(\*{0,1})="(.+?)"}i,
    %r{(filename|name)(\*{0,1})='(.+?)'}i,
    %r{(filename|name)(\*{0,1})=(.+?);}i
  ].freeze

  def filename_from_content_disposition
    # workaround for: NoMethodError: undefined method `filename' for #<Mail::UnstructuredField:0x007ff109e80678>
    begin
      filename = part.header[:content_disposition].try(:filename)
    rescue
      begin
        case part.header[:content_disposition].to_s
        when *CONTENT_DISPOSTION_FILENAME_REGEXPS
          filename = $3
        end
      rescue
        Rails.logger.debug { 'Unable to get filename' }
      end
    end

    begin
      case part.header[:content_disposition].to_s
      when *CONTENT_DISPOSTION_FILENAME_REGEXPS
        filename = $3
      end
    rescue
      Rails.logger.debug { 'Unable to get filename' }
    end

    # as fallback, use raw values
    if filename.blank?
      case headers['Content-Disposition'].to_s
      when *CONTENT_DISPOSTION_FILENAME_REGEXPS
        filename = $3
      end
    end

    filename
  end

  def filename_from_file_body
    mail_local = Channel::EmailParser.new.parse(file_body)

    if mail_local[:subject].present?
      "#{mail_local[:subject]}.eml"
    elsif headers['Content-Description'].present?
      "#{headers['Content-Description']}.eml".force_encoding('utf-8')
    else
      'Mail.eml'
    end
  rescue
    'Mail.eml'
  end

  MIME_TYPE_TO_FILENAME = {
    'message/delivery-status': %w[txt delivery-status],
    'text/plain':              %w[txt document],
    'text/html':               %w[html document],
    'video/quicktime':         %w[mov video],
    'image/jpeg':              %w[jpg image],
    'image/jpg':               %w[jpg image],
    'image/png':               %w[png image],
    'image/gif':               %w[gif image],
    'text/calendar':           %w[ics calendar],
  }.freeze

  def filename_from_content_type(content_type)
    (_, ext) = MIME_TYPE_TO_FILENAME.find { |type, _ext| content_type.match?(%r{^#{Regexp.quote(type)}}i) }

    return if !ext

    if headers['Content-Description'].present?
      "#{headers['Content-Description']}.#{ext[0]}".force_encoding('utf-8')
    else
      "#{ext[1]}.#{ext[0]}"
    end
  end

  def filename_ensure_unique(filename, attachments)
    if filename =~ %r{^(.*?)\.(.+?)$}
      local_filename = $1
      local_extension = $2
    end

    1.upto(1000) do |i|
      break if !attachments.find { |attachment| attachment[:filename] == filename }

      filename = if local_extension.present?
                   "#{local_filename}#{i}.#{local_extension}"
                 else
                   "#{local_filename}#{i}"
                 end
    end

    filename
  end

  CONTENT_TYPE_ID_WITH_EXT_REGEX = %r{(.+?\..{2,6})@.+?}i
  CONTENT_TYPE_ID_WITHOUT_EXT_REGEX = %r{(.+?)@.+?}i

  def filename_from_content_type_id
    # generate file name based on content-id with file extension
    if headers['Content-ID'].present? && headers['Content-ID'] =~ CONTENT_TYPE_ID_WITH_EXT_REGEX && $1.present?
      return $1
    end

    # e. g. Content-Type: video/quicktime
    if (content_type = headers['Content-Type'])
      filename = filename_from_content_type(content_type)

      return filename if filename.present?
    end

    # generate file name based on content-id without file extension
    if headers['Content-ID'].present? && headers['Content-ID'] =~ CONTENT_TYPE_ID_WITHOUT_EXT_REGEX && $1.present?
      return $1
    end

    nil
  end

  CONTENT_TYPE_FILENAME_REGEXES = [
    %r{(filename|name)(\*{0,1})="(.+?)"(;|$)}i,
    %r{(filename|name)(\*{0,1})='(.+?)'(;|$)}i,
    %r{(filename|name)(\*{0,1})=(.+?)(;|$)}i
  ].freeze

  def filename_from_content
    filename = filename_from_content_disposition

    if filename.blank?
      # for some broken sm mail clients (X-MimeOLE: Produced By Microsoft Exchange V6.5)
      filename = part.header[:content_location].to_s.dup.force_encoding('utf-8')
    end

    # generate file name based on content type
    if filename.blank? && headers['Content-Type'].present? && headers['Content-Type'].match?(%r{^message/rfc822}i)
      filename = filename_from_file_body
    end

    # e. g. Content-Type: video/quicktime; name="Video.MOV";
    if filename.blank?
      CONTENT_TYPE_FILENAME_REGEXES.each do |regexp|
        if headers['Content-Type'] =~ regexp
          filename = $3
          break
        end
      end
    end

    ensure_encoding(filename)
  end

  def ensure_encoding(filename)
    return if filename.blank?

    # workaround for mail gem - decode filenames
    # https://github.com/zammad/zammad/issues/928
    filename = Mail::Encodings.value_decode(filename)

    if filename.dup.force_encoding('UTF-8').valid_encoding?
      return filename
    end

    filename.utf8_encode(fallback: :read_as_sanitized_binary)
  end
end
