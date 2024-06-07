# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Chat < Zammad::TranslationCatalog::Extractor::Base
  # title: '...'
  # scrollHint: '...'
  EXTRACT_REGEX = %r{(?:title|\w+Hint):\s*#{LITERAL_STRING_REGEX}}

  # Extract some unmarked strings from the chat coffee files.
  def extract_from_string(string, filename)
    return if string.empty?

    collect_extracted_strings(filename, string, EXTRACT_REGEX)
  end

  def find_files
    # Only execute for Zammad, not for addons.
    return [] if options['addon_path']

    [
      "#{base_path}/public/assets/chat/chat.coffee",
      "#{base_path}/public/assets/chat/chat-no-jquery.coffee",
    ]
  end
end
