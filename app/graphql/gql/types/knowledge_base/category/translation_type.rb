# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Category
  class TranslationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Category Translation'

    field :title, String, null: false

    belongs_to :kb_locale, Gql::Types::KnowledgeBase::LocaleType, null: false
    belongs_to :category, Gql::Types::KnowledgeBase::CategoryType, null: false

    def self.pundit_object(object)
      object.category
    end

    # A translation exposes nothing beyond its category's title, so it must be
    #   readable wherever the category itself is (`CategoryType` uses the same
    #   check). Without this, the inherited `show?` default would demand
    #   editor/reader access and make the category tree of an otherwise
    #   publicly visible answer (e.g. in `categoryTreeTranslation`) blow up for
    #   agents without knowledge base permissions.
    def self.nested_access_pundit_method
      :show_any?
    end

    def self.direct_access_pundit_method
      :show_any?
    end
  end
end
