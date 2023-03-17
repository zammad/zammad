# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Tag::Assignment::Remove < Tag::Assignment::Base
    description 'Removes a tag from an object.'

    argument :tag, String, description: 'Name of the tag to remove'
    argument :object_id, GraphQL::Types::ID, description: 'Object to remove the tag from'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(tag:, object_id:)
      object = fetch_object(object_id)

      { success: object.tag_remove(tag, context.current_user.id) }
    end
  end
end
