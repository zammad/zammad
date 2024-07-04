# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStartPolicy < ApplicationPolicy
  def create?
    access?(__method__)
  end

  def update?
    access?(__method__)
  end

  def show?
    access?(__method__)
  end

  def destroy?
    access?(__method__)
  end

  private

  def access?(_method)
    return true if user.group_access? record.group_id, :create

    not_authorized Exceptions::UnprocessableEntity
      .new __('This user does not have access to the given group')
  end
end
