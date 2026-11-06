# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads the text of a ticket message's attachment, one class per family of file types in this directory, each naming
#   the types it takes. A file of a type no reader takes is not read; an addon adds a reader the same way, without a
#   list to change.
class Service::AI::Tool::ReadAttachment::Reader
  # Zammad's default for an incoming mail and for indexing an attachment: a larger file is not read.
  MAX_FILE_SIZE = 10.megabytes

  # Types that say nothing of the content, so the file's name tells it: none, the general one, and the Excel type that
  #   Windows browsers and Outlook give a CSV file where Excel is installed.
  GENERAL_TYPES = ['', 'application/octet-stream', 'application/vnd.ms-excel'].freeze

  # UTF-16 and UTF-32, as Windows tools write them with a byte order mark, such as PowerShell's logs, or as a sender
  #   declares them: their Latin text is valid UTF-8 with zero bytes after every letter, so the shared conversion, which
  #   tries UTF-8 before the declared charset, never reaches it. UTF-32's little-endian mark starts as UTF-16's does, so
  #   the longer marks come first. Without a mark, both are big-endian.
  BYTE_ORDER_MARKS = {
    "\xFF\xFE\x00\x00".b => Encoding::UTF_32LE, "\x00\x00\xFE\xFF".b => Encoding::UTF_32BE,
    "\xFF\xFE".b => Encoding::UTF_16LE, "\xFE\xFF".b => Encoding::UTF_16BE,
  }.freeze
  # Detection reads every byte it gets, about 2.5 seconds a megabyte, and every page of a text decodes the file again;
  #   the start of a file tells its charset as well as the whole.
  DETECTION_SAMPLE = 64.kilobytes

  # Detection tells multi-byte charsets well but guesses single-byte ones badly — German as Greek, with full
  #   confidence —, so a file without a charset is read in the system language's legacy one, as browsers read a page
  #   without one (WHATWG's locale fallback).
  LEGACY_CHARSETS = {
    %w[ru uk bg be mk sr] => 'Windows-1251', %w[pl cs sk hu hr sl ro] => 'Windows-1250', %w[el] => 'Windows-1253',
    %w[tr] => 'Windows-1254', %w[he] => 'Windows-1255', %w[ar fa] => 'Windows-1256', %w[lt lv et] => 'Windows-1257',
    %w[vi] => 'Windows-1258', %w[th] => 'Windows-874',
  }.freeze
  DEFAULT_LEGACY_CHARSET = 'Windows-1252'.freeze

  WIDE_CHARSETS = {
    'utf-16le' => Encoding::UTF_16LE, 'utf-16be' => Encoding::UTF_16BE, 'utf-16' => Encoding::UTF_16BE,
    'utf-32le' => Encoding::UTF_32LE, 'utf-32be' => Encoding::UTF_32BE, 'utf-32' => Encoding::UTF_32BE,
  }.freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  UNKNOWN_TYPE = 'Files of this type cannot be read.'.freeze
  TOO_LARGE    = "The file is larger than #{MAX_FILE_SIZE / 1.megabyte} MB, the most that is read.".freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # A file's text, or why it could not be read.
  Reading = Data.define(:text, :reason) do
    def self.of(text)
      new(text:, reason: nil)
    end

    def self.refused(reason)
      new(text: nil, reason:)
    end

    def read?
      reason.nil?
    end
  end

  class_attribute :mime_types, :extensions, instance_accessor: false, default: [].freeze

  attr_reader :file

  class << self
    # @param file [Store] an attachment of a ticket message
    # @return [Reading]
    def read(file)
      reader = for_file(file)
      return Reading.refused(UNKNOWN_TYPE) if reader.nil?
      return Reading.refused(TOO_LARGE) if file.size.to_i > MAX_FILE_SIZE

      reader.new(file).read
    end

    private

    # @param mime_types [Array<String>] the types the reader takes
    # @param extensions [Array<String>] the endings of the file names it takes, for a file stored with no type but the
    #   general one
    def takes(mime_types:, extensions:)
      self.mime_types = mime_types.freeze
      self.extensions = extensions.freeze
    end

    def for_file(file)
      type = Service::AI::Tool::StoredFile.mime_type(file)
      return descendants.find { |reader| reader.mime_types.include?(type) } if GENERAL_TYPES.exclude?(type)

      extension = File.extname(file.filename.to_s).delete_prefix('.').downcase
      descendants.find { |reader| reader.extensions.include?(extension) }
    end
  end

  # @param file [Store]
  def initialize(file)
    @file = file
  end

  # @return [Reading]
  def read
    raise NotImplementedError
  end

  private

  # The file's text in UTF-8, converted from the charset it was stored with, else from the one detected, as a mail's
  #   text is.
  def decoded_content
    content  = file.content
    charset  = Service::AI::Tool::StoredFile.charset(file)
    mark     = BYTE_ORDER_MARKS.keys.find { |bytes| content.start_with?(bytes) }
    declared = WIDE_CHARSETS[charset.to_s.downcase]
    return wide_content(content.byteslice(mark.bytesize..), BYTE_ORDER_MARKS[mark]) if mark
    return wide_content(content, declared) if declared

    TextEncoding.utf8_encode(content, from: charset || detected_charset(content), fallback: :read_as_sanitized_binary).delete_prefix("\uFEFF")
  end

  def detected_charset(content)
    return if content.dup.force_encoding(Encoding::UTF_8).valid_encoding?

    detected = CharDet.detect(content.byteslice(0, DETECTION_SAMPLE))['encoding']
    multi_byte?(detected) ? detected : legacy_charset
  end

  # 0xE4 leads a sequence in every multi-byte charset and is a character of its own in every single-byte one.
  def multi_byte?(charset)
    charset.present? && !"\xE4".b.force_encoding(Encoding.find(charset)).valid_encoding?
  rescue ArgumentError
    false
  end

  def legacy_charset
    language = Setting.get('locale_default').to_s.split('-').first

    LEGACY_CHARSETS.find { |languages, _charset| languages.include?(language) }&.second || DEFAULT_LEGACY_CHARSET
  end

  def wide_content(bytes, encoding)
    bytes.dup.force_encoding(encoding).encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
  end

  # Last, because loading the readers runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end
