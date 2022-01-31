# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::Frontend < Generators::TranslationCatalog::Extractor::Base

  def extract_from_string(string, filename) # rubocop:disable Metrics/AbcSize
    return if string.empty?

    # @T / @Ti
    literal_string_regex = %r{('|")(.+?)(?<!\\)\1}
    t_regex = %r{@Ti?\(?\s*#{literal_string_regex}}

    # App.i18n.translate(Content|Plain|Inline)
    translate_regex = %r{App\.i18n\.translate(?:Content|Plain|Inline)\(\s*#{literal_string_regex}}

    # i18n.t
    i18n_t_regex = %r{i18n\.t\(\s*#{literal_string_regex},?}

    # __()
    underscore_regex = %r{__\(\s*#{literal_string_regex},?\s*\)}

    # __() with multiline ''' string
    multiline_string_regex = %r{(''')\n((?:\n|.)*?)\n'''}m
    underscore_multiline_regex = %r{__\(\s*#{multiline_string_regex}\s*\)}

    [t_regex, translate_regex, i18n_t_regex, underscore_regex, underscore_multiline_regex].each do |r|
      string.scan(r) do |match|
        result = match[1].gsub(%r{\\'}, "'")
        next if match[0].eql?('"') && result.include?('#{')

        strings << result
        references[result] ||= Set[]
        references[result] << filename
      end
    end
    validate_strings
  end

  def find_files(base_path)
    files = []
    ['app/assets/**', 'public/assets/chat', 'public/assets/chat/views', 'public/assets/form'].each do |dir|
      files += Dir.glob("#{base_path}/#{dir}/*.js")
      files += Dir.glob("#{base_path}/#{dir}/*.eco")
      files += Dir.glob("#{base_path}/#{dir}/*.coffee")
    end
    ['app/frontend/apps/**', 'app/frontend/common/**', 'app/frontend/entry_points/**'].each do |dir|
      files += Dir.glob("#{base_path}/#{dir}/*.ts")
      files += Dir.glob("#{base_path}/#{dir}/*.vue")
    end
    files.reject { |d| d.include?('layout_ref') }
  end
end
