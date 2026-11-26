// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { inject, provide, shallowRef, type InjectionKey, type ShallowRef } from 'vue'

type TicketSidebarContainer = Readonly<ShallowRef<HTMLElement | string | null>>

// The keep-alive cache holds several ticket views, each with its own sidebar container. A selector
//   resolves against the document, so a view rendering in the background would miss its own.
const TICKET_SIDEBAR_CONTAINER_KEY = Symbol(
  'ticket-sidebar-container',
) as InjectionKey<TicketSidebarContainer>

export const provideTicketSidebarContainer = (container: TicketSidebarContainer) =>
  provide(TICKET_SIDEBAR_CONTAINER_KEY, container)

// A sidebar rendered on its own, as in component specs, has no ticket sidebar around it.
export const useTicketSidebarContainer = () =>
  inject(TICKET_SIDEBAR_CONTAINER_KEY, shallowRef('#ticketSidebar'))
