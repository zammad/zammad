# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class LinkUpdates < BaseSubscription
    include Gql::Concerns::HandlesPossibleObjects

    description 'Updates to link records'

    argument :object_id, GraphQL::Types::ID, required: true, description: 'Linked object identifier'
    argument :target_type, String, required: true, description: 'Target type'

    field :links, [Gql::Types::LinkType], null: true, description: 'Link records'

    possible_objects ::Ticket, ::KnowledgeBase::Answer::Translation

    def authorized?(object_id:, target_type:)
      fetch_object(object_id)
    end

    def update(object_id:, target_type:)
      object = Gql::ZammadSchema.object_from_id(object_id)

      links = Service::Link::List
        .new(current_user: context.current_user)
        .execute(object:, target_type:)

      { links: links }
    end
  end
end
