# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::CategoriesControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    access(__method__)
  end

  def create?
    verify_parent(__method__)
  end

  def update?
    access(__method__) && verify_parent(__method__)
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

  def verify_parent(method)
    if record.params[:parent_id].blank?
      return user.permissions?('knowledge_base.editor')
    end

    parent = KnowledgeBase::Category.find(record.params[:parent_id])

    KnowledgeBase::CategoryPolicy.new(user, parent).send(method)
  end
end
