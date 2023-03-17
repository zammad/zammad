# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  def update?
    access(__method__)
  end

  private

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::CategoryPolicy.new(user, object).send(method)
  end
end
