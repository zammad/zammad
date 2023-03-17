# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::AnswersControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    access(__method__)
  end

  def create?
    verify_category(__method__)
  end

  def update?
    access(__method__) && verify_category(__method__)
  end

  def destroy?
    access(__method__)
  end

  private

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::AnswerPolicy.new(user, object).send(method)
  end

  def verify_category(method)
    new_category = KnowledgeBase::Category.find(record.params[:category_id])

    KnowledgeBase::CategoryPolicy.new(user, new_category).send(method)
  end
end
