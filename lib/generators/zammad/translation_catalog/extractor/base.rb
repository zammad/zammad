# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::Base

  attr_reader   :options
  attr_accessor :extracted_strings

  def initialize(options:)
    @options = options
    @extracted_strings = Zammad::TranslationCatalog::ExtractedStrings.new
  end

  def extract_translatable_strings
    find_files.each do |file|
      extract_from_string(File.read(file), file.remove("#{base_path}/"))
    end
  end

  def extract_from_string(string, filename)
    raise NotImplementedError
  end

  def find_files
    raise NotImplementedError
  end

  def base_path
    options['addon_path'] || Rails.root.to_s
  end
end
