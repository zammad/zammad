# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::TranslationCatalogGenerator < Rails::Generators::Base
  class_option :check, type: :boolean, required: false, desc: 'Only check if the catalog file is up-to-date.'
  class_option :addon_path, type: :string, required: false, banner: '/path/to/addon', desc: 'Generate catalog for the specified addon module only.'

  def generate
    options_valid?
    strings, references = extract_strings base_path
    return if strings.count.zero?

    write_catalog(strings, references)
  end

  private

  def options_valid?
    if options['addon_path'] && !Dir.exist?(options['addon_path'])
      raise "Error: cannot find directory #{options['addon_path']}."
    end

    true
  end

  DATE_FORMAT_LEGEND = <<~LEGEND.chomp
    #. These placeholders are supported:
    #. - 'dd' - 2-digit day
    #. - 'd' - day
    #. - 'mm' - 2-digit month
    #. - 'm' - month
    #. - 'yyyy' - year
    #. - 'yy' - last 2 digits of year
    #. - 'SS' - 2-digit second
    #. - 'MM' - 2-digit minute
    #. - 'HH' - 2-digit hour (24h)
    #. - 'l' - hour (12h)
    #. - 'P' - Meridian indicator ('am' or 'pm')
  LEGEND

  def extract_strings(path)
    strings = Set[]
    references = {}
    # rubocop:disable Rails/Output
    print "Extracting strings from #{path}..."
    %i[Ruby Erb Frontend].each do |type|
      backend = "Generators::TranslationCatalog::Extractor::#{type}".constantize.new
      backend.extract_translatable_strings path
      strings.merge backend.strings
      references.merge!(backend.references) { |_key, oldval, newval| newval + oldval }
    end
    puts "#{strings.count} strings found."
    # rubocop:enable Rails/Output
    [strings, references]
  end

  def write_catalog(strings, references)

    pot = build_pot_content(strings, references)

    target_filename = "#{target_path}.pot"

    # rubocop:disable Rails/Output
    if options['check']
      original_file_content = File.read(target_filename)
      if original_file_content.eql? pot
        puts "File #{target_filename} is up-to-date."
        return
      else
        puts "File #{target_filename} is not up-to-date, please run 'rails generate translation_catalog' to update it."
        exit! # rubocop:disable Rails/Exit
      end
    end

    puts "Writing translation catalog file #{target_filename}."
    File.write(target_filename, pot)
    # rubocop:enable Rails/Output
  end

  def build_pot_content(strings, references)
    # Don't set a POT-Creation-Date to avoid unneccessary changes in Git.
    pot = <<~POT_HEADER
      msgid ""
      msgstr ""
      "Project-Id-Version: #{product_name}\\n"
      "POT-Creation-Date: \\n"
      "PO-Revision-Date: \\n"
      "Last-Translator: \\n"
      "Language-Team: \\n"
      "Language: en_US\\n"
      "MIME-Version: 1.0\\n"
      "Content-Type: text/plain; charset=UTF-8\\n"
      "Content-Transfer-Encoding: 8bit\\n"

    POT_HEADER

    # Add the default date/time format strings for 'en_US' as translations to
    #   the source catalog file. They will be read into the Translation model
    #   and can be customized via the translations admin GUI.
    pot += <<~FORMAT_STRINGS if !options['addon_path']
      #. Default date format to use for the current locale.
      #{DATE_FORMAT_LEGEND}
      msgid "FORMAT_DATE"
      msgstr "mm/dd/yyyy"

      #. Default date/time format to use for the current locale.
      #{DATE_FORMAT_LEGEND}
      msgid "FORMAT_DATETIME"
      msgstr "mm/dd/yyyy l:MM P"

    FORMAT_STRINGS

    strings.to_a.sort.each do |s|
      references[s].to_a.sort.each do |ref|
        pot += "#: #{ref}\n"
      end
      pot += <<~POT_ENTRY
        msgid "#{escape_for_po(s)}"
        msgstr ""

      POT_ENTRY
    end

    pot
  end

  # Escape: \ -> \\, " -> \" and newline -> literal \n
  def escape_for_po(str)
    # Not sure why, but six backslashes are needed here to produce two in the result.
    str.gsub(%r{\\}, '\\\\\\').gsub(%r{"}, '\\"').gsub(%r{\n}, '\\n')
  end

  def base_path
    options['addon_path'] || Rails.root.to_s
  end

  def target_path
    FileUtils.mkdir_p("#{base_path}/i18n")
    "#{base_path}/i18n/#{product_name.downcase}"
  end

  def product_name
    return 'zammad' if !options['addon_path']

    File.basename options['addon_path']
  end
end

# Allow Rails to find the generator
class TranslationCatalogGenerator < Generators::TranslationCatalog::TranslationCatalogGenerator
end
