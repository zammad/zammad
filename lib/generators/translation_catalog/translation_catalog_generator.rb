# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::TranslationCatalogGenerator < Rails::Generators::Base
  class_option :check, type: :boolean, required: false, desc: 'Only check if the catalog file is up-to-date.'
  class_option :addon_path, type: :string, required: false, banner: '/path/to/addon', desc: 'Generate catalog for the specified addon module only.'

  # Make sure .descendants always has the full list.
  Mixin::RequiredSubPaths.eager_load_recursive Generators::TranslationCatalog, __dir__

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
    extracted_strings = Generators::TranslationCatalog::ExtractedStrings.new
    # rubocop:disable Rails/Output
    print "Extracting strings from #{base_path}… "
    Generators::TranslationCatalog::Extractor::Base.descendants.each do |klass|
      backend = klass.new(options: options)
      backend.extract_translatable_strings
      extracted_strings.merge! backend.extracted_strings
    end
    puts "#{extracted_strings.count} strings found."
    # rubocop:enable Rails/Output
    extracted_strings
  end

  def write_strings(extracted_strings)
    Generators::TranslationCatalog::Writer::Base.descendants.each do |klass|
      klass.new(options: options).write(extracted_strings)
    end
  end

  def base_path
    options['addon_path'] || Rails.root.to_s
  end
end

# Allow Rails to find the generator
class TranslationCatalogGenerator < Generators::TranslationCatalog::TranslationCatalogGenerator
end
