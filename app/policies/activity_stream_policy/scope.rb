# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ActivityStreamPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if customer?
        scope.where(id: nil)
      elsif group_ids.blank?
        scope.where(permission_id: permission_ids, group_id: nil)
      else
        scope.where(permission_id: [*permission_ids, nil], group_id: [*group_ids, nil])
          .where.not('permission_id IS NULL AND group_id IS NULL')
      end
    end

    private

    def customer?
      !user.permissions?(%w[admin ticket.agent])
    end

    def permission_ids
      @permission_ids ||= user.permissions_with_child_ids
    end

    def group_ids
      @group_ids ||= user.group_ids_access('read')
    end
  end
end
