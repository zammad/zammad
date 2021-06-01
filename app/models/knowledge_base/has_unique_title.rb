# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# requires scope "neighbors_of" to find translations in same scope
class KnowledgeBase
  module HasUniqueTitle
    extend ActiveSupport::Concern

    included do
      validate :validate_title_uniqueness
    end

    private

    def validate_title_uniqueness
      return if self
           .class
           .where(kb_locale_id: kb_locale_id, title: title)
           .where.not(id: id)
           .neighbours_of(self)
           .none?

      errors.add(:title, 'is already used')
    end
  end
end
