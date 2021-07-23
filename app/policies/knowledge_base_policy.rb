# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  def edit?
    user&.permissions?('knowledge_base.editor')
  end
end
