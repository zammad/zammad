# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Tag < BaseQuery

    description 'Search for tags'

    argument :input, Gql::Types::Input::AutocompleteSearch::InputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::EntryType], null: false

    def resolve(input:)
      input = input.to_h
      query = input[:query]
      limit = input[:limit] || 10

      search_tags(query: query, limit: limit).map { |t| coerce_to_result(t) }
    end

    def search_tags(query:, limit:)
      # Show some tags even without a query.
      if query.strip.empty?
        return Tag::Item.left_outer_joins(:tags).group(:id).order('COUNT(tags.tag_item_id) DESC, name ASC').limit(limit)
      end

      Tag::Item.where('name_downcase LIKE ?', "%#{query.strip.downcase}%").order(name: :asc).limit(limit)
    end

    def coerce_to_result(tag)
      {
        value: Gql::ZammadSchema.id_from_object(tag),
        label: tag.name,
      }
    end

  end
end
