# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::CategoriesControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    access(__method__)
  end

  def create?
    verify_parent
  end

  def update?
    access(__method__) && verify_parent
  end

  def destroy?
    access(__method__)
  end

  private

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::CategoryPolicy.new(user, object).send(method)
  end

  def verify_parent
    if record.params[:parent_id].blank?
      parent = KnowledgeBase.find(record.params[:knowledge_base_id])

      return KnowledgeBasePolicy.new(user, parent).update?
    end

    parent = KnowledgeBase::Category.find(record.params[:parent_id])

    KnowledgeBase::CategoryPolicy.new(user, parent).update?
  end
end
