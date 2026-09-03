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

  # Ordering a list - picking its sorting mode, and arranging it by hand while that mode is `manual`
  #   - writes a column of the node the list belongs to, so it is reserved for editors of that node.
  #   The category in the URL is the parent of both of its lists.
  #
  # Deliberately not this policy's own #update?, which also runs #verify_parent against
  #   `params[:parent_id]` - a param these actions never carry, so it would fall back to checking the
  #   knowledge base and skip the category entirely. #access alone is the parent check.
  #
  # The same question the desktop view asks of the same node (`Pundit.authorize current_user, node,
  #   :update?` in Service::KnowledgeBase::Reorder::Base#execute), so both stacks agree on who may
  #   order a list. Without these the actions fall through to #method_missing and the
  #   `knowledge_base.*` default of Controllers::KnowledgeBase::BaseControllerPolicy, which lets a
  #   reader reorder.
  def reorder_categories?
    access(:update?)
  end

  def reorder_answers?
    access(:update?)
  end

  # The collection route carries no `:id`, and the knowledge base is the parent of the top level.
  def reorder_root_categories?
    KnowledgeBasePolicy.new(user, knowledge_base).update?
  end

  private

  def knowledge_base
    @knowledge_base ||= KnowledgeBase.find(record.params[:knowledge_base_id])
  end

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::CategoryPolicy.new(user, object).send(method)
  end

  def verify_parent
    if record.params[:parent_id].blank?
      return KnowledgeBasePolicy.new(user, knowledge_base).update?
    end

    parent = KnowledgeBase::Category.find(record.params[:parent_id])

    KnowledgeBase::CategoryPolicy.new(user, parent).update?
  end
end
