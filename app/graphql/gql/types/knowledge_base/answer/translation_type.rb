# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer
  class TranslationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Knowledge Base Answer Translation'

    field :title, String, null: false

    # Contains all categories of the answer (already translated).
    field :category_tree_translation, [Gql::Types::KnowledgeBase::Category::TranslationType], null: false

    belongs_to :kb_locale, Gql::Types::KnowledgeBase::LocaleType, null: false
    belongs_to :answer, Gql::Types::KnowledgeBase::AnswerType, null: false
    belongs_to :content, Gql::Types::KnowledgeBase::Answer::Translation::ContentType, null: false

    def category_tree_translation
      object.answer.category.self_with_parents.map { |c| c.translation_preferred(object.kb_locale) }.reverse
    end
  end
end
