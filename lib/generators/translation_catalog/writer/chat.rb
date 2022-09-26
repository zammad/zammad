# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Writer::Chat < Generators::TranslationCatalog::Writer::Base

  def write(strings)

    # Only execute for Zammad, not for addons.
    return if options['addon_path']

    # Do not run in CI.
    return if options['check']

    content = serialized(translation_map(strings))
    ['public/assets/chat/chat.coffee', 'public/assets/chat/chat-no-jquery.coffee'].each do |f|
      write_file(f, content)
    end
  end

  private

  def write_file(file, content)
    target_file = Rails.root.join(file)
    before = target_file.read
    puts "Writing chat asset file #{target_file}." # rubocop:disable Rails/Output
    after = before.sub(%r{(# ZAMMAD_TRANSLATIONS_START\n).*(    # ZAMMAD_TRANSLATIONS_END)}m) do |_match|
      $1 + content + $2
    end
    target_file.write(after)
  end

  def serialized(map)
    string = ''
    map.keys.sort.each do |locale|
      string += "      '#{locale}':\n"
      map[locale].keys.sort.each do |source|
        string += "        '#{escape_for_js(source)}': '#{escape_for_js(map[locale][source])}'\n"
      end
    end
    string
  end

  def translation_map(strings)
    sources = source_strings(strings)
    map = {}
    Locale.all.each do |locale|
      next if locale.locale.start_with?('en')

      trans = translations(sources, locale.locale)

      map[locale.alias.presence || locale.locale] = trans if trans.present?
    end
    map
  end

  def source_strings(strings)
    strings.sorted_values.select do |s|
      s.references.any? { |f| f.include?('public/assets/chat/') }
    end.map(&:string)
  end

  def translations(sources, locale)
    string_map = Translation.strings_for_locale(locale).select do |source, _entry|
      sources.include?(source)
    end.transform_values(&:translation)

    # Add strings that might be missing from translation file.
    (sources - string_map.keys).each do |missing_source|
      string_map[missing_source] = ''
    end

    return if string_map.values.count(&:blank?) > 3

    string_map
  end
end
