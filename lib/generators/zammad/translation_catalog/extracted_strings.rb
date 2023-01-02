# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::ExtractedStrings < SimpleDelegator
  def initialize
    super({})
  end

  def <<(extracted_string)
    string = extracted_string.string
    # validate
    if string.length > 3000
      raise "Found a string that is longer than the allowed 3000 characters: '#{string}'"
    end

    if key? string
      self[string].merge! extracted_string
    else
      self[string] = extracted_string
    end
  end

  def merge!(other)
    other.each_value do |s|
      self << s
    end
  end

  def sorted_values
    keys.sort.map { |k| self[k] }
  end
end
