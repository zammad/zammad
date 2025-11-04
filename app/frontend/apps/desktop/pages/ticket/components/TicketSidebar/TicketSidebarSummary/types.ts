// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { TicketAiAssistanceSummary } from '#shared/graphql/types.ts'

export interface SummaryItem {
  label: string
  key: keyof TicketAiAssistanceSummary | (keyof TicketAiAssistanceSummary)[]
  active: boolean
}

export interface SummaryConfig {
  open_questions: boolean
  upcoming_events: boolean
  customer_sentiment: boolean
  generate_on: string
}
