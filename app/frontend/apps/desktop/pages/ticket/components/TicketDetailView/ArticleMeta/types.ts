// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

export interface ChannelMetaField {
  label: string
  name: string
  component: unknown
  links?: { label: string; api: boolean; url: string; target: string }[]
  icon?: string
  order: number
  value?: unknown
  props?: Record<string, unknown>
  show?: (article: TicketArticle) => boolean
}
