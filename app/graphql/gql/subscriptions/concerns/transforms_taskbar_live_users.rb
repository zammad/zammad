# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The live user list of a taskbar key, shared by the subscriptions that push one.
#
# Each entity has a subscription of its own, because each needs the permission of *its* users (see
#   Taskbar::TriggersSubscriptions#live_user_subscription_class) - but what they read out of the
#   taskbar is the same: `preferences[:tasks]`, as collected by Taskbar#collect_related_tasks.
module Gql::Subscriptions::Concerns::TransformsTaskbarLiveUsers
  extend ActiveSupport::Concern

  included do
    subscription_scope :current_user_id

    argument :key, String, description: 'Taskbar key to filter for.'
    argument :app, Gql::Types::Enum::TaskbarAppType, description: 'Taskbar app to filter for.'
  end

  def subscribe(key:, app:)
    response(Taskbar.find_by(key: key, user_id: context.current_user.id, app: app))
  end

  def update(key:, app:)
    response(object)
  end

  private

  def response(taskbar_item)
    { live_users: transform_tasks(taskbar_item) }
  end

  def transform_tasks(taskbar_item)
    return [] if taskbar_item.blank?

    taskbar_item
      .preferences
      .fetch(:tasks, [])
      .filter_map { |task| transform_single_task(task) }
  end

  # Dropped rather than nulled for a user the current one may not look at: `user` is non-null, and
  #   an entry without one would be an avatar of nobody. Without the check the whole subscription
  #   fails on it - Gql::Types::UserType raises, which is the same trap
  #   Gql::Types::KnowledgeBase::AnswerType#edited_by works around on the same subsystem.
  #
  # It only ever bites the knowledge base list: a ticket live user list is subscribed by a
  #   `ticket.agent`, and #nested_show? lets those see every user outright.
  def transform_single_task(task)
    user = ::User.find_by(id: task[:user_id])

    return if user.nil?
    return if !Pundit.policy(context.current_user, user).nested_show?

    {
      user: user,
      apps: transform_task_apps(task[:apps]),
    }
  end

  def transform_task_apps(apps)
    apps.map do |app, data|
      {
        name:             app,
        editing:          data[:changed],
        last_interaction: data[:last_contact],
      }
    end
  end
end
