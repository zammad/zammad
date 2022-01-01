# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
