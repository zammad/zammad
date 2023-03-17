# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
    return if !user.permissions?('ticket.agent')

    user.groups.access(:create).include? record.group
  end
end
