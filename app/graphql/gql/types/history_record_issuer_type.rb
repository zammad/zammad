# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class HistoryRecordIssuerType < Gql::Types::BaseUnion
    description 'History record issuer'
    possible_types Gql::Types::UserType,
                   Gql::Types::TriggerType,
                   Gql::Types::JobType,
                   Gql::Types::PostmasterFilterType,
                   Gql::Types::ObjectClassType

    # Explicit type resolution is needed because of the pseudo
    # ObjectClassType.
    def self.resolve_type(object, _context)
      {
        ::Job              => Gql::Types::JobType,
        ::PostmasterFilter => Gql::Types::PostmasterFilterType,
        ::Trigger          => Gql::Types::TriggerType,
        ::User             => Gql::Types::UserType
      }.fetch(object.class, Gql::Types::ObjectClassType)
    end
  end
end
