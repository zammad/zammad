# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::Public::CategoriesControllerPolicy < ApplicationPolicy
  def index?
    return true if user&.permissions?('knowledge_base.editor')
    return true if record.present?

    false
  end
end
