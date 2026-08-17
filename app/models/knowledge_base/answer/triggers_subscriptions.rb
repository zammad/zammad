# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on knowledge base answer changes.
#
# Uses a plain #after_commit, not #after_update_commit: content edits happen on
#   KnowledgeBase::Answer::Translation, which `belongs_to :answer, touch: true` — a
#   touch-only commit on the answer that #after_update_commit does not catch (see
#   TriggersKnowledgeBaseContentUpdates for the same reasoning).
module KnowledgeBase::Answer::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    return if destroyed?

    Gql::Subscriptions::KnowledgeBase::AnswerUpdates.trigger(self, arguments: { answer_id: Gql::ZammadSchema.id_from_object(self) })
  end
end
