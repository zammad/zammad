# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class CategoryType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Category'

    field :category_icon, String, null: false
    field :position, Integer, null: false

    field :translations, [Gql::Types::KnowledgeBase::Category::TranslationType], null: false

    belongs_to :parent, Gql::Types::KnowledgeBase::CategoryType
    belongs_to :knowledge_base, Gql::Types::KnowledgeBaseType, null: false

    def translations
      ::KnowledgeBase::Category::Translation.where(category_id: object.id)
    end
  end
end
