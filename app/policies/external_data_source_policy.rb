# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ExternalDataSourcePolicy < ApplicationPolicy
  def fetch?
    send :"fetch_#{record.downcase}?"
  end

  private

  def fetch_group?
    user.permissions?('admin.group')
  end

  def fetch_organization?
    user.permissions?(%w[admin.organization ticket.agent])
  end

  def fetch_user?
    user.permissions?(%w[admin.user ticket.agent])
  end

  def fetch_ticket?
    user.permissions?(%w[ticket.agent ticket.customer])
  end
end
