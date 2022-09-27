# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Writer::ViewTemplates < Generators::TranslationCatalog::Writer::Base

  def write(_strings)

    # Only execute for Zammad, not for addons.
    return if options['addon_path']

    # Do not run in CI.
    return if options['check']

    extractor = Generators::TranslationCatalog::Extractor::ViewTemplates.new(options: options)
    extractor.extract_translatable_strings

    extractor.extracted_strings.sorted_values.each do |extracted_string|
      Locale.all.each do |locale|
        next if locale.locale.start_with?('en')

        handle_template(extracted_string, locale)
      end
    end
  end

  private

  def handle_template(extracted_string, locale)
    target_filename = extracted_string.references.first.sub(%r{/en.}, "/#{locale.alias.presence || locale.locale}.")
    translation = Translation.cached_strings_for_locale(locale.locale)[extracted_string.string]&.translation
    return if translation.blank?

    create_or_update_file(target_filename, translation)
  end

end
