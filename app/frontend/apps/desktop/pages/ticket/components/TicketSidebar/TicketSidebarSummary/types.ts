// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketAiAssistanceSummary } from '#shared/graphql/types.ts'

export interface SummaryItem {
  label: string
  key: keyof TicketAiAssistanceSummary | (keyof TicketAiAssistanceSummary)[]
  active: boolean
  type?: 'list' | 'paragraphs'
}
