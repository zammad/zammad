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

export const sortedByPriorityPlugins = searchPlugins.sort((a, b) => a.priority - b.priority)

export const sortedByNamePlugins = searchPlugins.sort((a, b) => a.name.localeCompare(b.name))

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

  const sortedByPriorityPlugins = computed(() =>
    plugins.value.sort((a, b) => a.priority - b.priority),
  )

  const sortedByNamePlugins = computed(() =>
    plugins.value.sort((a, b) => a.name.localeCompare(b.name)),
  )

  const searchPluginNames = computed(() => plugins.value.map((plugin) => plugin.name))

  // The plugins the detailed search may show a tab for. An entity whose quicksearch group ships
  //   before its detailed-search table does opts out with `detailSearchDisabled`, and then has to
  //   stay out of the tab list *and* out of the `searchCounts` query feeding the tab counters —
  //   asking for a count nobody can display would be a wasted round trip per keystroke.
  const detailSearchPlugins = computed(() =>
    plugins.value.filter((plugin) => !plugin.detailSearchDisabled),
  )

  const sortedByNameDetailSearchPlugins = computed(() =>
    detailSearchPlugins.value.toSorted((a, b) => a.name.localeCompare(b.name)),
  )

  const detailSearchPluginNames = computed(() =>
    detailSearchPlugins.value.map((plugin) => plugin.name),
  )

  return {
    plugins,
    sortedByPriorityPlugins,
    sortedByNamePlugins,
    searchPluginNames,
    detailSearchPlugins,
    sortedByNameDetailSearchPlugins,
    detailSearchPluginNames,
  }
}
