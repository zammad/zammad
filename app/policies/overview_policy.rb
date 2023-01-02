# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OverviewPolicy < ApplicationPolicy

  # Permission to use an overview is not implicitly granted to
  #   admins, so that they don't see all overviews in their list.
  def use?
    # User must always have one role assigned.
    return false if user_has_assigned_role?

    # If overview is restricted by individual users, user must be included.
    if record.user_ids.count.positive? && record.user_ids.exclude?(user.id)
      return false
    end

    true
  end

  def show?
    user_is_admin? || use?
  end

  def create?
    user_is_admin?
  end

  def update?
    user_is_admin?
  end

  def destroy?
    user_is_admin?
  end

  private

  def user_is_admin?
    user.permissions?(['admin.overview'])
  end

  def user_has_assigned_role?
    (user.role_ids.to_set & record.role_ids.to_set).count.zero?
  end
end
