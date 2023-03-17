# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Forward declaration for manual eager loading below.
module Zammad::TranslationCatalog; end

class Zammad::TranslationCatalogGenerator < Rails::Generators::Base

  desc <<~DESCRIPTION
    Create the translation catalog file for Zammad or an addon

    Example:
        # Regenerate the catalog for Zammad
        rails generate zammad:translation_catalog

        # Regenerate for an addon
        rails generate zammad:translation_catalog --addon-path /path/to/addon

        # Perform additional tasks such as updating template files from translations
        rails generate zammad:translation_catalog --full
  DESCRIPTION

  class_option :check, type: :boolean, required: false, desc: 'Only check if the catalog file is up-to-date.'
  class_option :addon_path, type: :string, required: false, banner: '/path/to/addon', desc: 'Generate catalog for the specified addon module only.'
  class_option :full, type: :boolean, required: false, desc: 'Perform additional tasks such as updating template files from translations.'

  # Make sure .descendants always has the full list.
  Mixin::RequiredSubPaths.eager_load_recursive Zammad::TranslationCatalog, "#{__dir__}/translation_catalog"

  def generate
    options_valid?
    strings = extract_strings
    return if strings.count.zero?

    write_strings(strings)
  end

  private

  def options_valid?
    if options['addon_path'] && !Dir.exist?(options['addon_path'])
      raise "Error: cannot find directory #{options['addon_path']}."
    end

    true
  end

  def extract_strings
    extracted_strings = Zammad::TranslationCatalog::ExtractedStrings.new
    # rubocop:disable Rails/Output
    print "Extracting strings from #{base_path}… "
    Zammad::TranslationCatalog::Extractor::Base.descendants.each do |klass|
      backend = klass.new(options: options)
      backend.extract_translatable_strings
      extracted_strings.merge! backend.extracted_strings
    end
    puts "#{extracted_strings.count} strings found."
    # rubocop:enable Rails/Output
    extracted_strings
  end

  def write_strings(extracted_strings)
    Zammad::TranslationCatalog::Writer::Base.descendants.each do |klass|
      writer = klass.new(options: options)
      writer.write(extracted_strings) if !writer.skip?
    end
  end

  def base_path
    options['addon_path'] || Rails.root.to_s
  end
end
