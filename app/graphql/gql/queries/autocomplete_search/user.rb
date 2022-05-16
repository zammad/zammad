# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::User < BaseQuery

    description 'Search for users'

    argument :query, String, required: true, description: 'Query from the autocomplete field'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::AutocompleteEntryType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    def resolve(query:, limit: 50)
      return [] if query.strip.empty?

      # TODO: Check if this is appropriate or if more complex logic from SearchController is needed.
      User.search(query: query, limit: limit, current_user: context.current_user).map { |u| coerce_to_result(u) }
    end

    def coerce_to_result(user)
      {
        value: Gql::ZammadSchema.id_from_object(user),
        label: user.fullname,
      }
    end

  end
end
