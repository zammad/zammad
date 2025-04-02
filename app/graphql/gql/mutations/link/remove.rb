# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Link::Remove < BaseMutation
    include Gql::Concerns::HandlesPossibleObjects

    description 'Remove link between objects'

    argument :input, Gql::Types::Input::LinkInputType, required: true, description: 'The link data'

    field :success, Boolean, description: 'Was the mutation successful?'

    possible_objects ::Ticket, ::KnowledgeBase::Answer::Translation

    def resolve(input:)
      source = fetch_object(input.source_id)
      target = fetch_object(input.target_id, permission: :update?)
      type = input.type

      ::Link.remove(
        link_type:                type,
        link_object_source:       source.class.name,
        link_object_source_value: source.id,
        link_object_target:       target.class.name,
        link_object_target_value: target.id
      )

      {
        success: true
      }
    end
  end
end
