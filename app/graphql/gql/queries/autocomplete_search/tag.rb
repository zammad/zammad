# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Tag < BaseQuery

    description 'Search for tags'

    argument :query, String, description: 'Query from the autocomplete field'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::AutocompleteEntryType], null: false

    def resolve(query:, limit: 10)
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
