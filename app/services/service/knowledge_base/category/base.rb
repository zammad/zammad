# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared write plumbing of the knowledge base category create and update services.
class Service::KnowledgeBase::Category::Base < Service::Base
  include Service::KnowledgeBase::Concerns::AppliesPermissions
  include Service::KnowledgeBase::Category::Concerns::AssignsTitle

  # Both services authorize through KnowledgeBase::CategoryPolicy, which needs a user.
  requires_current_user!

  private

  # `knowledge_base_id` and `parent_id` are independent columns and no validation relates them, so a
  #   parent from another knowledge base would save happily and leave a category hanging in a tree
  #   it does not belong to.
  def ensure_parent_of_knowledge_base!(knowledge_base, parent)
    return if parent.nil?
    return if parent.knowledge_base_id == knowledge_base.id

    raise Exceptions::UnprocessableContent, __('The selected parent category does not belong to this knowledge base.')
  end
end
