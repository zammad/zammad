# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Re-runs the vector indexing decision for every answer below a category, after a move changed
# whether that subtree is excluded from the index. The per-record path does the actual work: each
# VectorIndexJob re-checks #vector_indexing_for_record? and upserts or removes accordingly, so this
# job does not have to know which direction the move went.
#
# The fan-out runs in the background rather than in the category's after_commit: a subtree can hold
# thousands of answers, and enqueuing one job per translation inline would block the request that
# moved the category.
class VectorIndexKnowledgeBaseCategoryResyncJob < ApplicationJob
  include HasActiveJobLock

  low_priority

  # The category can be destroyed before the job runs, leaving nothing to resync.
  discard_on ActiveJob::DeserializationError

  def lock_key
    # "VectorIndexKnowledgeBaseCategoryResyncJob/KnowledgeBase::Category/42"
    "#{self.class.name}/KnowledgeBase::Category/#{arguments[0].id}"
  end

  def perform(category)
    return if !Service::AI::VectorDB::Available.execute(ping: false)

    # The moved category is indexable, but a descendant of it can still be excluded in its own right.
    KnowledgeBase::Answer::Translation
      .where(answer: category.self_with_children_answers.in_vector_indexable_category)
      .pluck(:id)
      .each { VectorIndexJob.perform_later('KnowledgeBase::Answer::Translation', it) }
  end
end
