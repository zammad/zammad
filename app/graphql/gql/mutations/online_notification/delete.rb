# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class OnlineNotification::Delete < BaseMutation
    description 'Marks notifications for active user as seen'

    argument :online_notification_id, GraphQL::Types::ID, required: true, loads: Gql::Types::OnlineNotificationType, description: 'The unique identifier of the notification which should be deleted.'
    field :success, Boolean, null: false, description: 'Was the notification deletion successful?'

    def resolve(online_notification:)
      online_notification.destroy

      { success: true }
    end

    def authorized?(online_notification:)
      pundit_authorized?(online_notification, :destroy?)
    end
  end
end
