# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotificationPolicy < ApplicationPolicy
  def show?
    owner?
  end

  def destroy?
    owner?
  end

  def update?
    owner?
  end

  private

  def owner?
    user == record.user
  end
end
