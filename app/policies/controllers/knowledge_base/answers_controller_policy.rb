# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::AnswersControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    return true if user.permissions?('knowledge_base.editor')

    object = record.klass.find(record.params[:id])
    object.can_be_published_aasm.internal? || object.can_be_published_aasm.published?
  end
end
