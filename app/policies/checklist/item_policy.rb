# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::ItemPolicy < ApplicationPolicy
  def show?
    Checklist::Item.for_user(user).exists?(id: record.id)
  end

  def create?
    return false if !ChecklistPolicy.new(user, record.checklist).show?

    true
  end

  def update?
    return false if !Checklist::Item.for_user(user).exists?(id: record.id)

    true
  end

  def destroy?
    Checklist::Item.for_user(user).exists?(id: record.id)
  end
end
