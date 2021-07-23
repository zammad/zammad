# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Public::CategoryPolicy < ApplicationPolicy
  def index?
    return true if user&.permissions?('knowledge_base.editor')
    return true if record.any?

    false
  end
end
