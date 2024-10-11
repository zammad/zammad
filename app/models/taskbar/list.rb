# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# User taskbar list actions.
module Taskbar::List
  extend ActiveSupport::Concern

  included do

    class << self

      def list(user, app: nil, restrict_entities: false)
        clause = { user: user }
        clause[:app] = app if app
        clause[:callback] = taskbar_entities if restrict_entities

        Taskbar.where(clause).reorder(:prio)
      end

      def reorder_list(user, order)
        order.each do |relation|
          taskbar = Taskbar.find(relation[:id])
          next if taskbar.user_id != user.id

          taskbar.update!(prio: relation[:prio])
        end
        trigger_list_update(user, 'desktop')
      end

      def trigger_list_update(user, app)
        user_id = Gql::ZammadSchema.id_from_internal_id('User', user.id)
        Gql::Subscriptions::User::Current::TaskbarItem::ListUpdates.trigger(nil, arguments: { user_id:, app: })
      end

    end

  end
end
