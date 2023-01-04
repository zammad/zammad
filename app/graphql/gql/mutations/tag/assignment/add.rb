# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Tag::Assignment::Add < Tag::Assignment::Base
    description 'Assign a tag to an object. This will create tags as needed.'

    argument :tag, String, description: 'Name of the tag to assign'
    argument :object_id, GraphQL::Types::ID, description: 'Object to assign the tag to'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(tag:, object_id:)
      object = fetch_object(object_id)

      { success: object.tag_add(tag, context.current_user.id) }
    end
  end
end
