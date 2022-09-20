# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Writer::Pot < Generators::TranslationCatalog::Writer::Base

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

  private

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
end
