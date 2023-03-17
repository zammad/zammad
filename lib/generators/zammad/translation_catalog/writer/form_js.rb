# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Writer::FormJs < Zammad::TranslationCatalog::Writer::Base

  optional true

  def write(extracted_strings)
    content = serialized(translation_map(extracted_strings))
    write_file('public/assets/form/form.js', content)
  end

  private

  def write_file(file, content)
    target_file = Rails.root.join(file)
    before = target_file.read
    after = before.sub(%r{(// ZAMMAD_TRANSLATIONS_START\n).*(    // ZAMMAD_TRANSLATIONS_END)}m) do |_match|
      $1 + content + $2
    end
    return if before == after

    puts "Updating file #{target_file}." # rubocop:disable Rails/Output
    target_file.write(after)
  end

  def serialized(map)
    string = ''
    map.keys.sort.each do |locale|
      string += "      '#{locale}': {\n"
      map[locale].keys.sort.each do |source|
        string += "        '#{escape_for_js(source)}': '#{escape_for_js(map[locale][source])}',\n"
      end
      string += "      },\n"
    end
    string
  end

  def translation_map(extracted_strings)
    sources = source_strings(extracted_strings)
    map = {}
    Locale.all.each do |locale|
      next if locale.locale.start_with?('en')

      trans = translations(sources, locale.locale)

      map[locale.alias.presence || locale.locale] = trans if trans.present?
    end
    map
  end

  def source_strings(extracted_strings)
    extracted_strings.sorted_values.select do |s|
      s.references.any? { |f| f.include?('public/assets/form/') }
    end.map(&:string)
  end

  def translations(sources, locale)
    string_map = Translation.cached_strings_for_locale(locale).select do |source, _entry|
      sources.include?(source)
    end.transform_values(&:translation)

    # Add strings that might be missing from translation file.
    (sources - string_map.keys).each do |missing_source|
      string_map[missing_source] = ''
    end

    return if string_map.values.count(&:blank?) > 1

    string_map
  end
end
