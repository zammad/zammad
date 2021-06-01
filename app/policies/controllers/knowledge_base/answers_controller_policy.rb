# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::KnowledgeBase::AnswersControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    return true if user.permissions?('knowledge_base.editor')

    object = record.klass.find(record.params[:id])
    object.can_be_published_aasm.internal? || object.can_be_published_aasm.published?
  end
end
