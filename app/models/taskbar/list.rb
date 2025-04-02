# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# User taskbar list actions.
module Taskbar::List
  extend ActiveSupport::Concern

  class_methods do
    def reorder_list(user, order)
      order_as_hash = order.each_with_object({}) do |elem, sum|
        sum[elem[:id]] = elem[:prio]
      end

      ActiveRecord::Base.transaction do |transaction|
        TaskbarPolicy::Scope
          .new(user, Taskbar)
          .resolve
          .where(id: order_as_hash.keys)
          .each do |taskbar|
            taskbar.skip_item_trigger = true
            taskbar.skip_live_user_trigger = true
            taskbar.update! prio: order_as_hash[taskbar.id]
          end

        transaction.after_commit do
          trigger_list_update(user, 'desktop')
        end
      end
    end

    def trigger_list_update(user, app)
      Gql::Subscriptions::User::Current::TaskbarItem::ListUpdates.trigger(nil, arguments: { app: }, scope: user.id)
    end
  end
end
