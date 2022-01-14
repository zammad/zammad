# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  def edit?
    user&.permissions?('knowledge_base.editor')
  end
end
