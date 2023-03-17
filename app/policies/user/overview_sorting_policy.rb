# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::OverviewSortingPolicy < ApplicationPolicy
  def show?
    same_user?
  end

  def create?
    same_user?
  end

  def update?
    same_user?
  end

  def destroy?
    same_user?
  end

  def same_user?
    record.user == user
  end
end
