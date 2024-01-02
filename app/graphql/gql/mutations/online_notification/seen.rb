# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class OnlineNotification::Seen < BaseMutation
    description 'Mark an online notification as seen'

    argument :object_id, GraphQL::Types::ID, description: 'ID of the object the notification is about.'

    field :success, Boolean, null: false, description: 'Did we successfully set the online notification to seen?'

    def authorized?(object_id:)
      relevant_notifications(object_id).all? do |notification|
        Pundit.authorize(context.current_user, notification, :update?)
      end
    end

    def resolve(object_id:)
      relevant_notifications(object_id).each do |notification|
        notification.update!(seen: true)
      end

      { success: true }
    end

    private

    def relevant_notifications(object_id)
      ::OnlineNotification.list_by_object(
        object_name(object_id),
        online_notification_object(object_id).id
      )
      .reject(&:seen?)
      .select { |notification| notification.user_id == context.current_user.id }
    end

    def object_name(object_id)
      @object_name ||= GlobalID::Locator.locate(object_id)&.class&.name
    end

    def online_notification_object(object_id)
      @online_notification_object ||= Gql::ZammadSchema.authorized_object_from_id(
        object_id,
        type: object_name(object_id).constantize,
        user: context.current_user,
      )
    end
  end
end
