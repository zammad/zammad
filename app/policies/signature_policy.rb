# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SignaturePolicy < ApplicationPolicy
  def show?
    return true if admin?
    return true if user.permissions?('ticket.agent') && record.active

    false
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    user.permissions?(['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365'])
  end
end
