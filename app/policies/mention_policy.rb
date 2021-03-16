class MentionPolicy < ApplicationPolicy
  def create?
    user.permissions?('ticket.agent')
  end
end
