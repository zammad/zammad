# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Ruby < Zammad::TranslationCatalog::Extractor::Base
  REMOVE_DOC_COMMENTS_REGEX = %r{^=begin.*?^=end}mx
  REMOVE_STANDARD_COMMENTS = %r{^\s*\#.*?$}mx

  # __()
  UNDERSCORE_REGEX = %r{__\(\s*#{LITERAL_STRING_REGEX}}

  def extract_from_string(string, filename)
    return if string.empty?

    # Remove doc comments
    string.gsub!(REMOVE_DOC_COMMENTS_REGEX, '')
    # Remove standard comments
    string.gsub!(REMOVE_STANDARD_COMMENTS, '')

    [TRANSLATE_REGEX, UNDERSCORE_REGEX].each do |r|
      collect_extracted_strings(filename, string, r)
    end
  end

  def find_files
    %w[config app db lib]
      .map do |dir|
        Dir.glob("#{base_path}/#{dir}/**/*.rb")
      end
      .flatten
  end
end
