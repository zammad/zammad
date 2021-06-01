# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MentionPolicy < ApplicationPolicy
  def create?
    user.permissions?('ticket.agent')
  end
end
