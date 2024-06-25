// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'

import type { TicketSidebarPlugin } from './types.ts'

const pluginModules = import.meta.glob<TicketSidebarPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./types.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const pluginFiles = Object.entries(pluginModules)
  .map<[string, TicketSidebarPlugin]>(([file, plugin]) => {
    const name = file.replace(/^.*\/([^/]+)\.ts$/, '$1')
    return [name, plugin]
  })
  .sort(([, p1], [, p2]) => p1.order - p2.order)

export const useTicketSidebarPlugins = () => {
  const { hasPermission } = useSessionStore()

  const plugins = pluginFiles
    .filter(([, plugin]) => hasPermission(plugin.permissions))
    .reduce<Record<string, TicketSidebarPlugin>>((acc, [name, plugin]) => {
      acc[name] = plugin
      return acc
    }, {})

  return plugins
}
