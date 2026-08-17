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

  # Reordering requires editor access on the collection's owner.
  def reorder_root_categories?
    knowledge_base_editor?
  end

  def reorder_categories?
    access(:update?)
  end

  def reorder_answers?
    access(:update?)
  end

  private

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::CategoryPolicy.new(user, object).send(method)
  end

  def verify_parent
    return knowledge_base_editor? if record.params[:parent_id].blank?

    parent = KnowledgeBase::Category.find(record.params[:parent_id])

    KnowledgeBase::CategoryPolicy.new(user, parent).update?
  end

  def knowledge_base_editor?
    knowledge_base = KnowledgeBase.find(record.params[:knowledge_base_id])

    KnowledgeBasePolicy.new(user, knowledge_base).update?
  end
end
