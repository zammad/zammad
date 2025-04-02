# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class GroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      return scope.all if Setting.get('customer_ticket_create_group_ids').blank?
      return scope.all if user.permissions?(['ticket.agent', 'admin.group'])

      allowed_group_ids = Auth::RequestCache.fetch_value("GroupPolicy/Scope/allowed_group_ids/#{user.id}") do
        Array.wrap(Setting.get('customer_ticket_create_group_ids')).map(&:to_i) | TicketPolicy::ReadScope.new(user).resolve.distinct(:group_id).pluck(:group_id)
      end

      scope.where(id: allowed_group_ids)
    end
  end
end
