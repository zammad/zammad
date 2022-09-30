# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class OnlineNotification::MarkAllAsSeen < BaseMutation
    description 'Marks notifications for active user as seen'

    argument :online_notification_ids, [GraphQL::Types::ID], required: true, loads: Gql::Types::OnlineNotificationType, description: 'Unique identifiers ofnotifications which should be deleted.'
    field :online_notifications, [Gql::Types::OnlineNotificationType], null: true, description: 'The seen notifications.'

    def authorized?(online_notifications:)
      online_notifications.all? do |elem|
        Pundit.authorize(context.current_user, elem, :update?)
      end
    end

    def resolve(online_notifications:)
      # TODO: we should only trigger one subscription for the complete mutation.
      # At the moment for every notification update a count subscription is triggered.
      online_notifications.each do |elem|
        elem.seen = true
        elem.save!
      end

      { online_notifications: online_notifications }
    end
  end
end
