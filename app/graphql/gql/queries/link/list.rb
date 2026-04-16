# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Link::List < BaseQuery
    include Gql::Concerns::HandlesLinkObjects

    description 'List linked objects'

    argument :object_id, GraphQL::Types::ID, required: true, description: 'Object ID'
    argument :target_type, String, required: true, description: 'Target type'

    type [Gql::Types::LinkType], null: true

    def resolve(object_id:, target_type:)
      object = fetch_visible_link_object(object_id)

      Service::Link::List
        .new(current_user: context.current_user)
        .execute(object:, target_type:)
    end
  end
end
