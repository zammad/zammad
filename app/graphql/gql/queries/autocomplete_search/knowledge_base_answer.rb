# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::KnowledgeBaseAnswer < BaseQuery

    description 'Search for knowledge base answers'

    argument :input, Gql::Types::Input::AutocompleteSearch::KnowledgeBaseAnswerInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::KnowledgeBaseAnswerEntryType], null: false

    def resolve(input:)
      input = input.to_h
      query = input[:query]
      limit = input[:limit] || 50

      return [] if query.strip.empty?

      translations = ::KnowledgeBase::Answer::Translation
        .search(
          query:,
          limit:,
          current_user: context.current_user,
        )
        .then { it || ::KnowledgeBase::Answer::Translation.none }
        .where.not(id: excluded_ids(input))
        .includes(:answer)

      category_titles = category_titles_for(translations)

      translations.map { coerce_to_result(it, category_titles) }
    end

    private

    def coerce_to_result(translation, category_titles)
      {
        value:      Gql::ZammadSchema.id_from_object(translation),
        label:      translation.title,
        heading:    category_titles[[translation.answer.category_id, translation.kb_locale_id]],
        visibility: translation.answer.visibility,
      }
    end

    def excluded_ids(input)
      return [] if input[:except_answer_ids].blank?

      Gql::ZammadSchema.internal_ids_from_ids(
        input[:except_answer_ids],
        type: ::KnowledgeBase::Answer::Translation,
      )
    end

    # Category titles for the whole result set at once, keyed by [category_id, kb_locale_id], so
    # #coerce_to_result never issues a query per translation. The title falls back the same way as
    # KnowledgeBase::Category#translation_preferred (answer's locale, then primary, then any), so a
    # category untranslated in the answer's locale still gets a heading.
    def category_titles_for(translations)
      ::KnowledgeBase::Category
        .preferred_translations_for(translations.map { |translation| [translation.answer.category_id, translation.kb_locale_id] })
        .transform_values { |translation| translation&.title }
    end
  end
end
