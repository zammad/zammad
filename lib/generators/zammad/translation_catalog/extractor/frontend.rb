# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Frontend < Zammad::TranslationCatalog::Extractor::Base
  # @T / @Ti
  T_REGEX = %r{@Ti?\(?\s*#{LITERAL_STRING_REGEX}}

  # App.i18n.translate(Content|Plain|Inline)
  TRANSLATE_REGEX = %r{App\.i18n\.translate(?:Content|Plain|Inline)\(\s*#{LITERAL_STRING_REGEX}}

  # i18n.t
  I18N_T_REGEX = %r{i18n\.t\(\s*#{LITERAL_STRING_REGEX},?}

  # $t
  GLOBAL_T_REGEX = %r{\$t\(\s*#{LITERAL_STRING_REGEX},?}

  # __()
  UNDERSCORE_REGEX = %r{__\(\s*#{LITERAL_STRING_REGEX},?\s*\)}

  # __() with multiline ''' string
  MULTILINE_STRING_REGEX = %r{(''')\n((?:\n|.)*?)\n'''}m
  UNDERSCORE_MULTILINE_REGEX = %r{__\(\s*#{MULTILINE_STRING_REGEX}\s*\)}

  def extract_from_string(string, filename)
    return if string.empty?

    [T_REGEX, TRANSLATE_REGEX, I18N_T_REGEX, GLOBAL_T_REGEX, UNDERSCORE_REGEX, UNDERSCORE_MULTILINE_REGEX].each do |r|
      collect_extracted_strings(filename, string, r)
    end
  end

  def find_files
    files = ['app/assets/**', 'public/assets/{chat,chat/views,form}'].map do |dir|
      Dir
        .glob("#{base_path}/#{dir}/*.{js,eco,coffee}")
        .reject { |f| f.include?('layout_ref') && !f.end_with?('layout_ref.coffee') }
    end

    files << Dir
      .glob("#{base_path}/app/frontend/{apps,shared}/**/*.{ts,vue}")
      .reject { |f| f.include? '/__tests__/' }

    files.flatten
  end
end
