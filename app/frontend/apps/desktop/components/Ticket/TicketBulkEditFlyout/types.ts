// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketBulkSelectorInput, TicketMacrosSelectorInput } from '#shared/graphql/types.ts'

import type { TicketBulkOverviewContext, TicketBulkSearchContext } from './useTicketBulkEdit.ts'
import type { ComputedRef, Ref } from 'vue'

export interface TicketBulkEditReturn {
  bulkEditActive: ComputedRef<boolean>
  checkedTicketIds: Ref<Set<ID>>
  /**
   * Dynamically changes ticket count based on bulk and ticket ids count
   */
  currentSelectedTicketCount: ComputedRef<number>
  groupIds: ComputedRef<Array<ID>>
  selectAllActive: Ref<boolean>
  bulkCount: Ref<number>
  bulkHasMoreItems: Ref<boolean>
  bulkContext: Ref<TicketBulkOverviewContext | TicketBulkSearchContext | undefined>
  bulkSelector: ComputedRef<TicketBulkSelectorInput>
  macrosSelector: ComputedRef<TicketMacrosSelectorInput>
  isBulkTaskRunning: ComputedRef<boolean>
  setOnSuccessCallback: (callback: () => void) => void
  onSuccessCallback?: () => void
  openBulkEditFlyout: () => void
}

export interface TicketBulkEditOptions {
  onSuccess?: () => void
}
