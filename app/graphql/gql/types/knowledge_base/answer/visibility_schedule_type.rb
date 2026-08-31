# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer
  # One transition an answer is going to make, as opposed to the state it is in now — which is what
  #   `visibility` on the answer says.
  #
  # Derived from the very same columns (CanBePublished#visibility_schedules): a publication state is
  #   stored as the date it is reached at, so a date still ahead *is* the schedule.
  class VisibilityScheduleType < Gql::Types::BaseObject
    description 'A scheduled visibility change of a knowledge base answer'

    field :visibility, Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType, null: false, description: 'Publication state the answer is going to reach'
    field :scheduled_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'When the answer reaches that state'
  end
end
