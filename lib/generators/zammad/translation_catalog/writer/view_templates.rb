# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Writer::ViewTemplates < Zammad::TranslationCatalog::Writer::Base

  optional true

  def write(_strings)
    extracted_strings.sorted_values.each do |extracted_string|
      Locale.all.each do |locale|
        next if locale.locale.start_with?('en')

        handle_template(extracted_string, locale)
      end
    end
  end

  private

  def extracted_strings
    Zammad::TranslationCatalog::Extractor::ViewTemplates.new(options: options).tap(&:extract_translatable_strings).extracted_strings
  end

  def handle_template(extracted_string, locale)
    target_filename = extracted_string.references.first.sub(%r{/en.}, "/#{locale.alias.presence || locale.locale}.")
    translation = Translation.cached_strings_for_locale(locale.locale)[extracted_string.string]&.translation
    return if translation.blank?

    create_or_update_file(target_filename, translation)
  end

end
