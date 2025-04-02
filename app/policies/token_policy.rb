# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TokenPolicy < ApplicationPolicy
  def destroy?
    return false if !record.visible_in_frontend?

    record.user == user
  end
end
