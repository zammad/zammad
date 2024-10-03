# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Tag < BaseQuery

    description 'Search for tags'

    argument :input, Gql::Types::Input::AutocompleteSearch::TagInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::EntryType], null: false

    def resolve(input:)
      Tag::Item
        .filter_or_recommended(normalize_query(input.query))
        .where.not(name: input.except_tags)
        .limit(input.limit || 10)
        .pluck(:name)
        .map do |elem|
          {
            value: elem,
            label: elem,
          }
        end
    end

    private

    def normalize_query(input)
      return '' if input == '*'

      input
        .delete_prefix('*')
        .delete_suffix('*')
    end
  end
end
