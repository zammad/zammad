# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class OnlineNotification::Seen < BaseMutation
    description 'Mark an online notification as seen'

    argument :object_id, GraphQL::Types::ID, description: 'ID of the object the notification is about.'

    field :success, Boolean, null: false, description: 'Did we successfully set the online notification to seen?'

    def resolve(object_id:)
      object = fetch_object(object_id)

      case object
      when ::OnlineNotification
        object.mark_as_seen!
      else
        ::OnlineNotification.mark_as_seen!(object, context.current_user)
      end

      { success: true }
    end

    private

    def fetch_object(object_id)
      Gql::ZammadSchema
        .authorized_object_from_id(
          object_id,
          user: context.current_user,
          type: nil
        )
    end
  end
end
