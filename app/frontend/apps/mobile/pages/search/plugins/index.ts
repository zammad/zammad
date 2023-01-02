// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { EnumSearchableModels } from '@shared/graphql/types'
import type { Component } from 'vue'
import { useSessionStore } from '@shared/stores/session'
import type { Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'

export interface SearchPlugin {
  model: EnumSearchableModels
  headerLabel: string
  searchLabel: string
  order: number
  link: string
  permissions: string[]
  icon?: string | IconProps
  iconBg?: string
  component: Component // component needs to have a slot called "default" and prop "entity"
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
