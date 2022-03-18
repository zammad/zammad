# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class MentionPolicy < ApplicationPolicy
  def create?
    user.permissions?('ticket.agent')
  end
end
