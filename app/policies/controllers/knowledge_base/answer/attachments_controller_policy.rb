# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::Answer::AttachmentsControllerPolicy < Controllers::ApplicationControllerPolicy
  def create?
    answer_policy.update?
  end

  def destroy?
    answer_policy.update?
  end

  def clone_to_form?
    answer_policy.show?
  end

  private

  def answer_policy
    @answer_policy ||= KnowledgeBase::AnswerPolicy.new(user, record.send(:answer))
  end
end
