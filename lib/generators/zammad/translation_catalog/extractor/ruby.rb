# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Ruby < Zammad::TranslationCatalog::Extractor::Base

  def extract_from_string(string, filename)
    return if string.empty?

    # Remove doc comments
    string.gsub!(%r{^=begin.*?^=end}mx, '')
    # Remove standard comments
    string.gsub!(%r{^\s*\#.*?$}mx, '')

    literal_string_regex = %r{('|")(.+?)(?<!\\)\1}

    # Translation.translate
    locale_regex = %r{['"a-z_0-9.&@:\[\]-]+}
    translate_regex = %r{Translation\.translate\(?\s*#{locale_regex},\s*#{literal_string_regex}}

    # __()
    underscore_regex = %r{__\(\s*#{literal_string_regex}}

    [translate_regex, underscore_regex].each do |r|
      string.scan(r) do |match|
        result = match[1].gsub(%r{\\'}, "'")
        next if match[0].eql?('"') && result.include?('#{')

        extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: result, references: [filename])
      end
    end
  end

  def find_files
    files = []
    %w[config app db lib].each do |dir|
      files += Dir.glob("#{base_path}/#{dir}/**/*.rb")
    end
    files
  end
end
