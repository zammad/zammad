# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Tag::Assignment::Add < BaseMutation
    description 'Assign a tag to an object. This will create tags as needed.'

    argument :tag, String, description: 'Name of the tag to assign'
    argument :object_id, GraphQL::Types::ID, description: 'Object to assign the tag to'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(tag:, object_id:)
      object = Gql::ZammadSchema.authorized_object_from_id(object_id, user: context.current_user, query: :update?, type: [::Ticket, ::User, ::KnowledgeBase::Answer])
      { success: object.tag_add(tag, context.current_user.id) }
    end
  end
end
