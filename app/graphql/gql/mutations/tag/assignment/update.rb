# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Tag::Assignment::Update < Tag::Assignment::Base
    description 'Update tags of an object. This will create tags as needed.'

    argument :tags, [String], description: 'Name of the tag to assign'
    argument :object_id, GraphQL::Types::ID, description: 'Object to update tags of'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(tags:, object_id:)
      object = fetch_object(object_id)

      { success: object.tag_update(tags, context.current_user.id) }
    end
  end
end
