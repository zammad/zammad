# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer
  class TranslationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Knowledge Base Answer Translation'

    field :title, String, null: false
    field :maybe_locale, String, description: 'Specified only for knowledge bases with multiple locales'

    # Contains all categories of the answer (already translated).
    field :category_tree_translation, [Gql::Types::KnowledgeBase::Category::TranslationType], null: false

    belongs_to :kb_locale, Gql::Types::KnowledgeBase::LocaleType, null: false
    belongs_to :answer, Gql::Types::KnowledgeBase::AnswerType, null: false
    belongs_to :content, Gql::Types::KnowledgeBase::Answer::Translation::ContentType, null: false

    def maybe_locale
      return if !KnowledgeBase.with_multiple_locales_exists?

      object.kb_locale.system_locale.locale.upcase
    end

    def category_tree_translation
      object.answer.category.self_with_parents.map { |c| c.translation_preferred(object.kb_locale) }.reverse
    end
  end
end
