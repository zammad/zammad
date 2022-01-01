# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::Base

  attr_accessor :strings, :references

  def initialize
    @strings = Set[]
    @references = {}
  end

  def extract_translatable_strings(base_path)
    find_files(base_path).each do |file|
      extract_from_string(File.read(file), file.remove("#{base_path}/"))
    end
  end

  def validate_strings
    @strings.to_a.each do |s|
      if s.length > 3000
        raise "Found a string that longer than than the allowed 3000 characters: '#{s}'"
      end
    end
  end

  def extract_from_string(string, filename)
    raise NotImplementedError
  end

  def find_files(base_path)
    raise NotImplementedError
  end
end
