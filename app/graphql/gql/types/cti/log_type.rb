# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Cti::LogType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields

    description 'Caller log entry of the CTI integration'

    field :direction, String, null: false
    field :state, String, null: false
    field :comment, String, null: true
    field :from, String, null: false
    field :to, String, null: false
    field :from_pretty, String, null: false
    field :to_pretty, String, null: false
    field :from_comment, String, null: true, description: 'Name the telephony backend sent for the calling side, e.g. the agent who dialled'
    field :to_comment, String, null: true, description: 'Name the telephony backend sent for the called side, e.g. the agent who answered or the queue'
    field :done, Boolean, null: false
    field :duration_waiting_time, Integer, null: true
    field :duration_talking_time, Integer, null: true
    field :from_matches, [Gql::Types::Cti::Log::CallerIdMatchType], null: false, description: 'Caller IDs matched to the calling number'
    field :to_matches, [Gql::Types::Cti::Log::CallerIdMatchType], null: false, description: 'Caller IDs matched to the called number'

    def from_pretty
      pretty(:from_pretty)
    end

    def to_pretty
      pretty(:to_pretty)
    end

    def from_matches
      object.preferences[:from] || []
    end

    def to_matches
      object.preferences[:to] || []
    end

    private

    # Older records may lack the stored pretty values, like Cti::Log#attributes handles it.
    def pretty(attribute)
      object.set_pretty if object.from_pretty.blank? || object.to_pretty.blank?

      object.public_send(attribute)
    end
  end
end
