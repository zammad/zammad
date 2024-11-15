// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { HistoryRecordEvent } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<HistoryRecordEvent> => {
  return {
    action: 'created',
  }
}
