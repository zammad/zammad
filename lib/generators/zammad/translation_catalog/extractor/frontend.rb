# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Frontend < Zammad::TranslationCatalog::Extractor::Base

  def extract_from_string(string, filename)
    return if string.empty?

    # @T / @Ti
    literal_string_regex = %r{('|")(.+?)(?<!\\)\1}
    t_regex = %r{@Ti?\(?\s*#{literal_string_regex}}

    # App.i18n.translate(Content|Plain|Inline)
    translate_regex = %r{App\.i18n\.translate(?:Content|Plain|Inline)\(\s*#{literal_string_regex}}

    # i18n.t
    i18n_t_regex = %r{i18n\.t\(\s*#{literal_string_regex},?}

    # $t
    global_t_regex = %r{\$t\(\s*#{literal_string_regex},?}

    # __()
    underscore_regex = %r{__\(\s*#{literal_string_regex},?\s*\)}

    # __() with multiline ''' string
    multiline_string_regex = %r{(''')\n((?:\n|.)*?)\n'''}m
    underscore_multiline_regex = %r{__\(\s*#{multiline_string_regex}\s*\)}

    [t_regex, translate_regex, i18n_t_regex, global_t_regex, underscore_regex, underscore_multiline_regex].each do |r|
      string.scan(r) do |match|
        result = match[1].gsub(%r{\\'}, "'")
        next if match[0].eql?('"') && result.include?('#{')

        extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: result, references: [filename])
      end
    end
  end

  def find_files
    files = []

    ['app/assets/**', 'public/assets/{chat,chat/views,form}'].each do |dir|
      files += Dir.glob("#{base_path}/#{dir}/*.{js,eco,coffee}").reject { |f| f.include?('layout_ref') && !f.end_with?('layout_ref.coffee') }
    end

    files += Dir.glob("#{base_path}/app/frontend/{apps,shared}/**/*.{ts,vue}").reject { |f| f.include? '/__tests__/' }
  end
end
