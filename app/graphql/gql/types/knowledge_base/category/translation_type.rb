# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Category
  class TranslationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Category Translation'

    field :title, String, null: false

    belongs_to :kb_locale, Gql::Types::KnowledgeBase::LocaleType, null: false
    belongs_to :category, Gql::Types::KnowledgeBase::CategoryType, null: false

    def self.pundit_object(object)
      object.category
    end
  end
end
