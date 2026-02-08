# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::ObjectAttributeExternalDataSource < BaseQuery

    description 'Search for values in object attributes for external data sources'

    argument :input, Gql::Types::Input::AutocompleteSearch::ObjectAttributeExternalDataSourceInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::ExternalDataSourceEntryType], null: false

    def authorized?(input:)
      ExternalDataSourcePolicy.new(context.current_user, input.object).fetch?
    end

    def resolve(input:)
      query = input.query
      limit = input.limit || 50

      return [] if query.strip.empty?

      attribute = ::ObjectManager::Attribute.get(object: input.object, name: input.attribute_name)

      raise "Could not find object attribute for #{input}." if !attribute

      Service::ExternalDataSource::Search.new.execute(
        attribute:      attribute,
        render_context: input.template_render_context.to_context_hash,
        term:           query,
        limit:          limit,
      )
    end
  end
end
