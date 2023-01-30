# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketLiveUserUpdates < BaseSubscription

    description 'Updates to ticket live users.'

    argument :user_id, GraphQL::Types::ID, loads: Gql::Types::UserType, description: 'ID of the user to receive updates for'
    argument :key, String, description: 'Taskbar key to filter for.'
    argument :app, Gql::Types::Enum::TaskbarAppType, description: 'Taskbar app to filter for.'

    field :live_users, [Gql::Types::Ticket::LiveUserType], description: 'Current live users from the ticket.'

    def authorized?(user:, key:, app:)
      context.current_user == user
    end

    def subscribe(user:, key:, app:)
      response(Taskbar.find_by(key: key, user_id: context.current_user.id, app: app))
    end

    def update(user:, key:, app:)
      response(object)
    end

    private

    def response(taskbar_item)
      { live_users: transform_tasks(taskbar_item) }
    end

    def transform_tasks(taskbar_item)
      tasks = taskbar_item.preferences[:tasks]
      return [] if tasks.blank?

      tasks = tasks.reject { |task| task[:user_id].eql?(context.current_user.id) }
      return [] if tasks.blank?

      tasks.map do |task|
        {
          user:             ::User.find_by(id: task[:user_id]),
          editing:          task[:changed],
          last_interaction: task[:last_contact],
          apps:             task[:apps],
        }
      end
    end
  end
end
