# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::KnowledgeBase::CategoriesControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    return if user.permissions?('knowledge_base.editor')

    record.klass.find(record.params[:id]).internal_content?
  end
end
