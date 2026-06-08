# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Link::Add < BaseMutation
    include Gql::Concerns::HandlesLinkObjects

    description 'Add a link between objects'

    argument :input, Gql::Types::Input::LinkInputType, required: true, description: 'The link data'

    field :link, Gql::Types::LinkType, null: true, description: 'The created link'

    requires_permission 'ticket.agent'

    def resolve(input:)
      source = fetch_visible_link_object(input.source_id)
      target = fetch_authorized_link_object(input.target_id)
      type   = input.type

      link = ::Link.add(
        link_type:                type,
        link_object_source:       source.class.name,
        link_object_source_value: source.id,
        link_object_target:       target.class.name,
        link_object_target_value: target.id
      )

      if !link.valid?
        return error_response({ message: link.errors.full_messages.first })
      end

      {
        link: {
          item: source,
          type: type
        }
      }
    end
  end
end
