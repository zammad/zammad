// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { injectLocal } from '@vueuse/shared'
import { type InjectionKey } from 'vue'

import type { TicketSidebarInformation } from '../types/sidebar.ts'

export const TICKET_SIDEBAR_SYMBOL = Symbol(
  'ticket-sidebar',
) as InjectionKey<TicketSidebarInformation>

export const useTicketSidebar = () => {
  return injectLocal(TICKET_SIDEBAR_SYMBOL) as TicketSidebarInformation
}
