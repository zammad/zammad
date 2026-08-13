# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::OnlineNotificationStandalone
  class DataUnionType < Gql::Types::BaseUnion
    description 'Union of data payloads for standalone online notifications'

    # Not extensible yet: OnlineNotificationStandalone validates 'kind' against
    #   a fixed list and OnlineNotificationStandaloneType#data builds only these
    #   two payloads, so an extension type could never be reached.
    possible_types Gql::Types::OnlineNotificationStandalone::BulkJobDataType,
                   Gql::Types::OnlineNotificationStandalone::KbAnswerGenerationFailedDataType
  end
end
