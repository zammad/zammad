# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Base
  LITERAL_STRING_REGEX = %r{('|")(.+?)(?<!\\)\1}

  # Translation.translate
  LOCALE_REGEX = %r{['"a-z_0-9.&@:\[\]-]+}
  TRANSLATE_REGEX = %r{Translation\.translate\(?\s*#{LOCALE_REGEX},\s*#{LITERAL_STRING_REGEX}}

  attr_reader   :options
  attr_accessor :extracted_strings

  def initialize(options:)
    @options = options
    @extracted_strings = Zammad::TranslationCatalog::ExtractedStrings.new
  end

  def extract_translatable_strings
    find_files.each do |file|
      extract_from_string(File.read(file), file.remove("#{base_path}/"))
    end
  end

  def extract_from_string(string, filename)
    raise NotImplementedError
  end

  def find_files
    raise NotImplementedError
  end

  def base_path
    options['addon_path'] || Rails.root.to_s
  end

  private

  COLLECT_EXTRACTED_STRINGS_REGEX = %r{\\'}

  def collect_extracted_strings(filename, string, regex)
    string.scan(regex) do |quotes_style, text|
      result = text.gsub(COLLECT_EXTRACTED_STRINGS_REGEX, "'")
      next if quotes_style == '"' && result.include?('#{')

      reference = build_reference(filename, string, quotes_style + text)
      extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: result, references: [reference])
    end
  end

  def build_reference(filename, string, substring)
    line_number = guess_line_number(string, substring)
    line_number.present? ? "#{filename}:#{line_number}" : filename
  end

  def guess_line_number(string, substring)
    index = string.index(substring)

    return if index.blank?

    string.slice(0..index).lines.count
  end
end
