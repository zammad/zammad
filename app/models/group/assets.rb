# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Group
  module Assets
    extend ActiveSupport::Concern

    def filter_unauthorized_attributes(attributes)
      return super if UserInfo.assets.blank? || UserInfo.assets.agent?

      attributes = super
      attributes.slice('id', 'name', 'name_last', 'follow_up_possible', 'reopen_time_in_days', 'active', 'parent_id')
    end

    def authorized_asset?
      return true if UserInfo.current_user.blank?

      allowed_group_ids = Auth::RequestCache.fetch_value("Group/Assets/authorized_asset/groups/#{UserInfo.current_user_id}") do
        GroupPolicy::Scope.new(UserInfo.current_user, Group).resolve.pluck(:id)
      end

      allowed_group_ids.include?(id)
    end
  end
end
