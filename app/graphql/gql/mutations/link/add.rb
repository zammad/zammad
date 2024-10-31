# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Link::Add < BaseMutation
    include Gql::Concerns::HandlesPossibleObjects

    description 'Add a link between objects'

    argument :input, Gql::Types::Input::LinkInputType, required: true, description: 'The link data'

    field :link, Gql::Types::LinkType, null: true, description: 'The created link'

    possible_objects ::Ticket, ::KnowledgeBase::Answer::Translation

    def resolve(input:)
      source = fetch_object(input.source_id)
      target = fetch_object(input.target_id, permission: :update?)
      type = input.type

      begin
        ::Link.add(
          link_type:                type,
          link_object_source:       source.class.name,
          link_object_source_value: source.id,
          link_object_target:       target.class.name,
          link_object_target_value: target.id
        )
      rescue ActiveRecord::RecordNotUnique
        return error_response({ message: __('Link already exists') })
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
