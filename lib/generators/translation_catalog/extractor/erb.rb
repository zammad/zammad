# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::Erb < Generators::TranslationCatalog::Extractor::Base

  def extract_from_string(string, filename)
    return if string.empty?

    # zt() / t()
    literal_string_regex = %r{(['"])(.+?)(?<!\\)\1}
    t_regex = %r{(?:#\{|\s)z?t\(?\s*#{literal_string_regex}}

    [t_regex].each do |r|
      string.scan(r) do |match|
        result = match[1].gsub(%r{\\'}, "'")
        next if match[0].eql?('"') && result.include?('#{')

        strings << Generators::TranslationCatalog::ExtractedString.new(string: result, references: [filename])
      end
    end
  end

  def find_files(base_path)
    files = []
    ['app/views/**'].each do |dir|
      files += Dir.glob("#{base_path}/#{dir}/*.erb")
    end
    files
  end
end
