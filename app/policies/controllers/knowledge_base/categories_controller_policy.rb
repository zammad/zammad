# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::CategoriesControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    return if user.permissions?('knowledge_base.editor')

    record.klass.find(record.params[:id]).internal_content?
  end
end
