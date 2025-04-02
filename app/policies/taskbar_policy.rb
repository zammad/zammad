# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TaskbarPolicy < ApplicationPolicy
  def create?
    owner?
  end

  def update?
    owner?
  end

  def show?
    owner?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user == record.user
  end
end
