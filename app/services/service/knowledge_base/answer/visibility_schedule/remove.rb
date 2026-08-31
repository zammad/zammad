# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Clears one visibility change a knowledge base answer is scheduled to make. The answer stays in the
#   state it is in — the change simply never happens.
#
# Idempotent: a state that is not scheduled at all is left alone rather than refused. The wanted end
#   state is reached either way, and the client removes an entry it is showing — one that has been
#   removed elsewhere, or that was reached in the meantime, is not something to report back to it.
class Service::KnowledgeBase::Answer::VisibilitySchedule::Remove < Service::KnowledgeBase::Answer::VisibilitySchedule::Base
  def execute
    # Scheduling is editing knowledge base content, so it follows the same rule as the knowledge base
    #   itself: only while it is active. Editor access to the answer is not asked on top of that: the
    #   only caller is the matching mutation, whose `answer_id` argument loads the record through
    #   AnswerPolicy#update? before the service is reached.
    active_knowledge_base!

    clear_schedule if answer.visibility_scheduled_at(visibility)

    answer
  end

  private

  # Only ever a date still ahead, which is what #visibility_scheduled_at answers: a state the answer
  #   has already reached is how it got where it is, and clearing that date would change its
  #   visibility now rather than cancel anything — which is the update mutation's job, not this one's.
  #
  # Not saved at all when there is nothing to clear, so an entry that is already gone does not bump
  #   the answer's `updated_at` or notify every open tab of a change that did not happen.
  #
  # Emptying a column cannot break the ordering validations of CanBePublished: they only compare the
  #   dates that are set.
  def clear_schedule
    answer[timestamp_column] = nil

    answer.save!
  end
end
