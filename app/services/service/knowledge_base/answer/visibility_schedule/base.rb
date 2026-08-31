# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared plumbing of the two services that manage the visibility changes an answer is scheduled to
#   make: which column a state lives in, and who may write it.
#
# A publication state is not stored, it is *derived* from the date each state was reached at (see
#   CanBePublished) — so scheduling a change means writing a date still ahead into that state's
#   column, and clearing one means emptying it again.
#
# Deliberately apart from Service::KnowledgeBase::Answer::Update, whose `visibility` only ever means
#   the state the answer is in *now*: the two write the same columns, and an ordinary save must
#   neither move a schedule nor cancel one.
class Service::KnowledgeBase::Answer::VisibilitySchedule::Base < Service::KnowledgeBase::Answer::Base
  attr_reader :answer, :visibility

  # @param answer [KnowledgeBase::Answer] answer whose schedule is being changed
  # @param visibility [Symbol] publication state the schedule is about, as sent by
  #   Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType
  def initialize(answer:, visibility:)
    @answer     = answer
    @visibility = visibility
  end

  private

  # Raises a KeyError for `draft`, which stores no date and can therefore not be scheduled — the
  #   schema rules it out (SchedulableVisibilityType), so reaching this is a programming error.
  def timestamp_column
    CanBePublished::SCHEDULABLE_VISIBILITIES.fetch(visibility)
  end
end
