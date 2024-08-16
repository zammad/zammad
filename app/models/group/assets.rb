# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Group
  module Assets
    extend ActiveSupport::Concern

    def filter_unauthorized_attributes(attributes)
      return super if UserInfo.assets.blank? || UserInfo.assets.agent?

      attributes = super
      attributes.slice('id', 'name', 'name_last', 'follow_up_possible', 'reopen_time_in_days', 'active', 'parent_id')
    end

    def authorized_asset?
      return true if UserInfo.assets.blank? || UserInfo.assets.agent? || Setting.get('customer_ticket_create_group_ids').blank?

      allowed_group_ids = Auth::RequestCache.fetch_value("Group/Assets/authorized_asset/groups/#{UserInfo.current_user_id}") do
        Array.wrap(Setting.get('customer_ticket_create_group_ids')).map(&:to_i) | TicketPolicy::ReadScope.new(UserInfo.current_user).resolve.distinct(:group_id).pluck(:group_id)
      end

      allowed_group_ids.include?(id)
    end
  end
end
