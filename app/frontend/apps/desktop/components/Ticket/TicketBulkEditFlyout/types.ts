// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketBulkOverviewContext, TicketBulkSearchContext } from './useTicketBulkEdit.ts'
import type { ComputedRef, Ref } from 'vue'

export interface TicketBulkEditReturn {
  bulkEditActive: ComputedRef<boolean>
  checkedTicketIds: Ref<Set<ID>>
  groupIds: ComputedRef<Array<ID>>
  selectAllActive: Ref<boolean>
  bulkCount: Ref<number>
  bulkHasMoreItems: Ref<boolean>
  bulkContext: Ref<TicketBulkOverviewContext | TicketBulkSearchContext | undefined>
  isBulkTaskRunning: ComputedRef<boolean>
  setOnSuccessCallback: (callback: () => void) => void
  onSuccessCallback?: () => void
  openBulkEditFlyout: () => void
}

export interface TicketBulkEditOptions {
  onSuccess?: () => void
}
