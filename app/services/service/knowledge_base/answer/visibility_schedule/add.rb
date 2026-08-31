# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Schedules a visibility change of a knowledge base answer: the answer reaches the given publication
#   state at the given point in time, and stays as it is until then.
#
# Replaces a schedule the same state already had — a state is reached at one date, so there is only
#   ever one of them per state, and moving it is what a client saves after editing an entry.
class Service::KnowledgeBase::Answer::VisibilitySchedule::Add < Service::KnowledgeBase::Answer::VisibilitySchedule::Base
  attr_reader :scheduled_at

  # @param answer [KnowledgeBase::Answer] answer to schedule the change for
  # @param visibility [Symbol] publication state the answer is to reach
  # @param scheduled_at [ActiveSupport::TimeWithZone] when it is to reach that state
  def initialize(answer:, visibility:, scheduled_at:)
    super(answer:, visibility:)

    @scheduled_at = scheduled_at
  end

  def execute
    # Scheduling is editing knowledge base content, so it follows the same rule as the knowledge base
    #   itself: only while it is active. Editor access to the answer is not asked on top of that: the
    #   only caller is the matching mutation, whose `answer_id` argument loads the record through
    #   AnswerPolicy#update? before the service is reached.
    active_knowledge_base!

    ensure_scheduled_for_the_future!
    ensure_state_not_reached_yet!

    answer[timestamp_column] = scheduled_at

    ensure_schedule_can_be_reached!

    # Writing the date is all there is to it: CanBePublished#schedule_touch queues the job that makes
    #   the answer surface once the date is reached, and the state is derived from the column from
    #   then on.
    answer.save!

    answer
  end

  private

  # Each refusal names the argument that has to change, not the column it was noticed on: the caller
  #   submitted a state and a date, and that is what it can correct. Gql::Mutations::KnowledgeBase
  #   ::Answer::VisibilitySchedule::Add passes the name on, and the flyout's fields carry it.
  #
  # No concern of the model's - a date in the past is a perfectly valid record. It would simply
  #   change the state at once, which is the update mutation's business, and it would do so as a
  #   schedule the client goes on showing.
  def ensure_scheduled_for_the_future!
    return if scheduled_at.present? && scheduled_at.future?

    raise Exceptions::InvalidAttribute.new('scheduledAt', __('A visibility change can only be scheduled for a point in time in the future.'))
  end

  # No concern of the model's either: overwriting a date that has passed with one in the future
  #   satisfies every ordering rule it has. What it does is take the answer *out* of a state it is
  #   in, right now - silently undoing a publication instead of scheduling anything.
  #
  # On the state rather than the date: no date makes this one schedulable again.
  def ensure_state_not_reached_yet!
    return if !publication_in_effect?(answer[timestamp_column])

    raise Exceptions::InvalidAttribute.new('visibility', __('The answer has already reached this visibility state, so a change to it cannot be scheduled.'))
  end

  # A scheduled change only takes effect if it ranks above whatever is in effect when it fires: the
  #   state is derived from the highest-ranked date that has *passed*
  #   (CanBePublished::StateMachine#calculated_state). So the dates have to ascend with the ranks.
  #
  # CanBePublished validates exactly that, and asking here is not duplication for its own sake: its
  #   three validations each report on the date they compare *from*, which is the wrong one to point
  #   at. Scheduling `internal` for after a pending archival trips `archived_after_internal`, whose
  #   error lands on `archived_at` - so the form would flag the archival the editor did not touch
  #   rather than the date they just picked. This says the same thing about the submitted date, and
  #   states the rule, since either the date or the state has to give.
  def ensure_schedule_can_be_reached!
    dates = CanBePublished::SCHEDULABLE_VISIBILITIES.each_value.filter_map { |column| answer[column] }

    return if dates.each_cons(2).all? { |earlier, later| earlier <= later }

    raise Exceptions::InvalidAttribute.new('scheduledAt', __('Visibility changes take effect in the order internal, published, archived, and can only be scheduled in that order.'))
  end
end
