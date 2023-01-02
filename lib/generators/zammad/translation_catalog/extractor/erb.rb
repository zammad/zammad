# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Erb < Zammad::TranslationCatalog::Extractor::Base

  def extract_from_string(string, filename)
    return if string.empty?

    # zt() / t()
    literal_string_regex = %r{(['"])(.+?)(?<!\\)\1}
    t_regex = %r{(?:#\{|\s)z?t\(?\s*#{literal_string_regex}}

    [t_regex].each do |r|
      string.scan(r) do |match|
        result = match[1].gsub(%r{\\'}, "'")
        next if match[0].eql?('"') && result.include?('#{')

        extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: result, references: [filename])
      end
    end
  end

  def find_files
    files = []
    ['app/views/**'].each do |dir|
      files += Dir.glob("#{base_path}/#{dir}/*.erb")
    end
    files
  end
end
