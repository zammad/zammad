// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketSidebarContext,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

import type { Component } from 'vue'

export interface TicketSidebarPlugin {
  title: string
  order: number
  component: Component
  permissions: string[]
  screens: TicketSidebarScreenType[]
  icon: string
  available?: (context: TicketSidebarContext) => boolean
}
