# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Generic < BaseQuery

    description 'Generic autocomplete search'

    argument :input, Gql::Types::Input::AutocompleteSearch::GenericInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::GenericEntryType], null: false

    def resolve(input:)
      input = input.to_h
      query = input[:query]
      limit = input[:limit] || 50

      return [] if query.blank?

      Service::Search
        .new(current_user: context.current_user,
             query:        query,
             objects:      input[:only_in] || Gql::Types::SearchResultType.searchable_models,
             options:      { limit: limit })
        .execute
        .flattened
        .map { |object| coerce_to_result(object) }
    end

    def coerce_to_result(object)
      {
        value:               object.id,
        label:               label(object),
        heading:             heading(object),
        heading_placeholder: heading_placeholder(object),
        object:              object,
      }
    end

    private

    def label(object)
      case object
      when ::User
        label_user(object)
      when ::Organization
        object.name
      when ::Ticket
        "##{object.number} - #{object.title}"
      end
    end

    def label_user(user)
      user.fullname.presence || user.phone.presence || user.login
    end

    def heading(object)
      case object
      when ::User
        object.organization&.name
      when ::Organization
        __('%s people')
      when ::Ticket
        label_user(object.customer)
      end
    end

    def heading_placeholder(object)
      case object
      when ::Organization
        [object.all_members.size]
      else
        []
      end
    end
  end
end
