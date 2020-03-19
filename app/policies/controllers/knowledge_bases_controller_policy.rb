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
