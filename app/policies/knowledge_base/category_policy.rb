# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::CategoryPolicy < ApplicationPolicy
  def show?
    return true if user&.permissions?('knowledge_base.editor')

    record.public_content?
  end

  private

  def user_required?
    false
  end
end
