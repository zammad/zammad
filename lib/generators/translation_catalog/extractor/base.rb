# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::Base

  attr_reader   :options
  attr_accessor :strings

  def initialize(options:)
    @options = options
    @strings = Generators::TranslationCatalog::ExtractedStrings.new
  end

  def extract_translatable_strings(base_path)
    find_files(base_path).each do |file|
      extract_from_string(File.read(file), file.remove("#{base_path}/"))
    end
  end

  def extract_from_string(string, filename)
    raise NotImplementedError
  end

  def find_files(base_path)
    raise NotImplementedError
  end
end
