# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::FormJs < Generators::TranslationCatalog::Extractor::Base

  # Extract some unmarked strings from form.js asset file.
  def extract_from_string(string, filename) # rubocop:disable Metrics/AbcSize
    return if string.empty?

    # display: '...'
    literal_string_regex = %r{('|")(.+?)(?<!\\)\1}
    extract_regex = %r{(?:display|placeholder):\s*#{literal_string_regex}}

    string.scan(extract_regex) do |match|
      result = match[1].gsub(%r{\\'}, "'")
      next if match[0].eql?('"') && result.include?('#{')

      strings << result
      references[result] ||= Set[]
      references[result] << filename
    end

    validate_strings
  end

  def find_files(base_path)
    # Only execute for Zammad, not for addons.
    return [] if options['addon_path']

    ["#{base_path}/public/assets/form/form.js"]
  end
end
