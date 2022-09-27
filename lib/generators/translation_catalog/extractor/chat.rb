# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::Chat < Generators::TranslationCatalog::Extractor::Base

  # Extract some unmarked strings from the chat coffee files.
  def extract_from_string(string, filename)
    return if string.empty?

    # title: '...'
    # scrollHint: '...'
    literal_string_regex = %r{('|")(.+?)(?<!\\)\1}
    extract_regex = %r{(?:title|\w+Hint):\s*#{literal_string_regex}}

    string.scan(extract_regex) do |match|
      result = match[1].gsub(%r{\\'}, "'")
      next if match[0].eql?('"') && result.include?('#{')

      extracted_strings << Generators::TranslationCatalog::ExtractedString.new(string: result, references: [filename])
    end
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
