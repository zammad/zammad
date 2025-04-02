# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Erb < Zammad::TranslationCatalog::Extractor::Base
  # zt() / t()
  LITERAL_STRING_REGEX = %r{(['"])(.+?)(?<!\\)\1}
  T_REGEX = %r{(?:#\{|\s)z?t\(?\s*#{LITERAL_STRING_REGEX}}

  def extract_from_string(string, filename)
    return if string.empty?

    collect_extracted_strings(filename, string, T_REGEX)
    collect_extracted_strings(filename, string, TRANSLATE_REGEX)
  end

  def find_files
    Dir.glob("#{base_path}/app/views/**/*.erb")
  end
end
