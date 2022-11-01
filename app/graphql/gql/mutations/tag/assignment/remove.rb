# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Tag::Assignment::Remove < BaseMutation
    description 'Removes a tag from an object.'

    argument :tag, String, description: 'Name of the tag to remove'
    argument :object_id, GraphQL::Types::ID, description: 'Object to remove the tag from'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(tag:, object_id:)
      object = Gql::ZammadSchema.authorized_object_from_id(object_id, user: context.current_user, query: :update?, type: [::Ticket, ::User, ::KnowledgeBase::Answer])
      { success: object.tag_remove(tag, context.current_user.id) }
    end
  end
end
