# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::KnowledgeBasesControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def init?
    true
  end

  def create?
    false
  end

  def destroy?
    false
  end
end
