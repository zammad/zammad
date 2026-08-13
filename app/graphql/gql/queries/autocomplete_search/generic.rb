# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Generic < BaseQuery

    description 'Generic autocomplete search'

    argument :input, Gql::Types::Input::AutocompleteSearch::GenericInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::GenericEntryType], null: false

    # Models this query can render: #label and #heading are implemented per
    #   model below, and #label is non-nullable. Searchable models added by
    #   extensions have no label support yet, so they must not be searched here.
    SUPPORTED_MODELS = [::Ticket, ::User, ::Organization].freeze

    def resolve(input:)
      input = input.to_h
      query = input[:query]
      limit = input[:limit] || 50

      return [] if query.blank?

      Service::Search
        .with_current_user(context.current_user)
        .execute(
          query:   query,
          objects: supported_objects(input[:only_in]),
          options: { limit: limit }
        )
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

    # Only an omitted argument selects the defaults — an explicitly empty
    #   'onlyIn' keeps its previous meaning of searching nothing.
    def supported_objects(only_in)
      return SUPPORTED_MODELS if only_in.nil?

      only_in & SUPPORTED_MODELS
    end

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
