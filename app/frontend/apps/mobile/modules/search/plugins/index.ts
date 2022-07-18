// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useSessionStore from '@shared/stores/session'
import { Component } from 'vue'

export interface SearchPlugin<T = unknown> {
  headerTitle: string
  order: number
  link: string
  permissions: string[]
  component: Component // component needs to have a slot called "default" and prop "entity"
  itemTitle?(entity: T): string // by default "title" field
}

const pluginsModules = import.meta.glob<SearchPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

const pluginsFiles = Object.entries(pluginsModules)
  .map<[string, SearchPlugin]>(([file, plugin]) => {
    const name = file.replace(/^.*\/([^/]+)\.ts$/, '$1')
    return [name, plugin]
  })
  .sort(([, p1], [, p2]) => p1.order - p2.order)

export const useSearchPlugins = () => {
  const { hasPermission } = useSessionStore()
  const plugins = pluginsFiles
    .filter(([, plugin]) => hasPermission(plugin.permissions))
    .reduce<Record<string, SearchPlugin>>((acc, [name, plugin]) => {
      acc[name] = plugin
      return acc
    }, {})
  return plugins
}
