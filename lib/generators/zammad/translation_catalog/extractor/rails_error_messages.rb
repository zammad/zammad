# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::RailsErrorMessages < Zammad::TranslationCatalog::Extractor::Base

  def extract_translatable_strings

    # Only execute for Zammad, not for addons.
    return if @options['addon_path']

    I18n.backend.load_translations
    find_error_messages(I18n.backend.translations[:en]).each do |error_message|
      extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: error_message, references: [])
    end
  end

  # Messages from doorkeeper are very technical and don't seem to be shown to the users.
  IGNORE_KEYS = %r{doorkeeper}

  def find_error_messages(hash)
    hash.reduce([]) do |result, (key, value)|
      next result if !value.is_a?(Hash)
      next result if key.match?(IGNORE_KEYS)

      result + (key == :errors ? flattened_values(value.fetch(:messages, {})) : find_error_messages(value))
    end.uniq
  end

  def flattened_values(hash)
    hash.values.reduce([]) do |result, value|
      next result + flattened_values(value) if value.is_a?(Hash)

      result.push(value)
    end
  end
end
