# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class BulkUpdateStatusStatusType < BaseEnum
    description 'Bulk update status type'

    value 'none', 'No bulk update in progress'
    value 'pending', 'Bulk update is pending and will start soon'
    value 'running', 'Bulk update is currently running'
    value 'succeeded', 'Bulk update completed successfully'
    value 'failed', 'Bulk update failed'
  end
end
