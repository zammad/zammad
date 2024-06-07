# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::FormJs < Zammad::TranslationCatalog::Extractor::Base
  # display: '...'
  EXTRACT_REGEX = %r{(?:display|placeholder):\s*#{LITERAL_STRING_REGEX}}

  # Extract some unmarked strings from form.js asset file.
  def extract_from_string(string, filename)
    return if string.empty?

    collect_extracted_strings(filename, string, EXTRACT_REGEX)
  end

  def find_files
    # Only execute for Zammad, not for addons.
    return [] if options['addon_path']

    ["#{base_path}/public/assets/form/form.js"]
  end
end
