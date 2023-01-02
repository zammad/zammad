# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::ExtractedString
  attr_accessor :string, :comment, :references, :skip_translation_sync

  def initialize(string:, references:, comment: nil, skip_translation_sync: false)
    @string = string
    @comment = comment
    @references = Set.new(references)
    @skip_translation_sync = skip_translation_sync
  end

  def merge!(other)
    if @string != other.string
      raise 'Cannot merge different strings.'
    end

    if other.comment
      @comment ||= ''
      @comment += other.comment
    end
    @references = references.merge other.references
    @skip_translation_sync &= other.skip_translation_sync
  end
end
