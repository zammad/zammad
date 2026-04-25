# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::OnlineNotificationStandalone
  class BulkJobDataType < Gql::Types::BaseObject
    description 'Data payload for bulk job standalone notifications'

    field :total, Integer, null: false
    field :failed_count, Integer, null: false
  end
end
