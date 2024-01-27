# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class EmailAddressPolicy < ApplicationPolicy
  def show?
    user.permissions?(['ticket.agent', 'admin.channel_email'])
  end
end
