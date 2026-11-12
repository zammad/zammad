// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import type { SearchPlugin } from '../types.ts'

const plugins = import.meta.glob<SearchPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./types.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const searchPlugins = Object.values(plugins)

export const searchPluginByName = keyBy(searchPlugins, 'name')

export const getSearchPlugin = (name: string) => searchPluginByName[name]

export const useSearchPlugins = () => {
  const { hasPermission } = useSessionStore()

  const plugins = computed(() =>
    searchPlugins.filter(
      (plugin) =>
        (!plugin.permissions || hasPermission(plugin.permissions)) &&
        (!plugin.show || plugin.show()),
    ),
  )

  // Copied before sorting: `sort` is in place, and the two orders are of one list.
  const sortedByPriorityPlugins = computed(() =>
    [...plugins.value].sort((a, b) => a.priority - b.priority),
  )

  const sortedByNamePlugins = computed(() =>
    [...plugins.value].sort((a, b) => a.name.localeCompare(b.name)),
  )

  const searchPluginNames = computed(() => plugins.value.map((plugin) => plugin.name))

  return {
    plugins,
    sortedByPriorityPlugins,
    sortedByNamePlugins,
    searchPluginNames,
  }
}
