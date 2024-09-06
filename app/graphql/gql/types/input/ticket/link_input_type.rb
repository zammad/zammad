# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class LinkInputType < Gql::Types::BaseInputObject
    description 'Represents a ticket link to another object.'

    argument :link_object_id, GraphQL::Types::ID, description: 'The target object to link to'
    argument :link_type, String, description: 'The link type to set, e.g. normal/parent/child'

    transform :load_link_object

    # Load the underlying object for the link_object_id, and return that instead.
    # We can't use loads: here because it requires a specific graphql type class.
    def load_link_object(payload)
      payload.to_h.tap do |p|
        p[:link_object] = Gql::ZammadSchema.authorized_object_from_id(
          p.delete(:link_object_id), type: ApplicationModel, user: context.current_user
        )
      end
    end
  end
end
