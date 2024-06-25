// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketSidebarContext } from '../../types.ts'
import type { Component } from 'vue'

export interface TicketSidebarPlugin {
  title: string
  order: number
  buttonComponent: Component
  contentComponent: Component
  permissions: string[]
  icon: string
  available?: (context: TicketSidebarContext) => boolean
}
