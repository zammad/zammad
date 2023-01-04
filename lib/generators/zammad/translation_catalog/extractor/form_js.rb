# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::FormJs < Zammad::TranslationCatalog::Extractor::Base

  # Extract some unmarked strings from form.js asset file.
  def extract_from_string(string, filename)
    return if string.empty?

    # display: '...'
    literal_string_regex = %r{('|")(.+?)(?<!\\)\1}
    extract_regex = %r{(?:display|placeholder):\s*#{literal_string_regex}}

    string.scan(extract_regex) do |match|
      result = match[1].gsub(%r{\\'}, "'")
      next if match[0].eql?('"') && result.include?('#{')

      extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: result, references: [filename])
    end
  end

  def find_files
    # Only execute for Zammad, not for addons.
    return [] if options['addon_path']

    ["#{base_path}/public/assets/form/form.js"]
  end
end
