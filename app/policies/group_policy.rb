# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class GroupPolicy < ApplicationPolicy
  def show?
    return true if admin?

    return true if user.group_access?(record, 'read')

    # check if user is customer for any tickets in this group
    Ticket.exists?(customer: user, group: record)
  end

  private

  def admin?
    user.permissions?('admin.group')
  end
end
