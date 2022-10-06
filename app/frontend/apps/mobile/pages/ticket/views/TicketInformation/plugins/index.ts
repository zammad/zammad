// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketQuery } from '@shared/graphql/types'
import type { RouteRecordRaw } from 'vue-router'

export interface TicketInformationPlugin {
  order: number
  label: string
  route: RouteRecordRaw & { name: string }
  condition?: (ticket?: TicketQuery['ticket']) => boolean
}

const pluginsModules = import.meta.glob<TicketInformationPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const ticketInformationPlugins = Object.values(pluginsModules).sort(
  (p1, p2) => p1.order - p2.order,
)

export const ticketInformationRoutes = ticketInformationPlugins.map(
  (plugin) => plugin.route,
)
