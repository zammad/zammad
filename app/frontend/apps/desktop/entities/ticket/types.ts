// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormRefParameter } from '#shared/components/Form/types.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'

import type { MenuState } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/types.ts'

import type { ComputedRef, Reactive, Ref } from 'vue'

export interface TicketInformation {
  ticket: ComputedRef<TicketById | undefined>
  ticketId: ComputedRef<ID>
  ticketInternalId: Ref<number>
  isTicketEditable: ComputedRef<boolean>
  form: FormRefParameter
  showTicketArticleReplyForm: () => void
  newTicketArticlePresent: Ref<boolean | undefined>
  highlightMenu: Reactive<MenuState>
}

export type BulkUpdateSyncResult = {
  async: false
  total: number
  failedCount: number
  invalidTicketIds: ID[]
}

export type BulkUpdateAsyncResult = {
  async: true
  total: number
}

export type BulkUpdateResult = BulkUpdateSyncResult | BulkUpdateAsyncResult
