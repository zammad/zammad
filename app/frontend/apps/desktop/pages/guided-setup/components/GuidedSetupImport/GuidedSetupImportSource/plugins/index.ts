// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumSystemImportSource } from '#shared/graphql/types.ts'

import type { Component } from 'vue'

export interface GuidedSetupImportSourcePlugin {
  source: EnumSystemImportSource
  label: string
  beta: boolean
  component: Component
  importEntities: Record<string, string>
  preStartHints?: string[]
  documentationURL: string
}

const pluginsModules = import.meta.glob<GuidedSetupImportSourcePlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const guidedSetupImportSourcePlugins = Object.values(
  pluginsModules,
).sort((p1, p2) => p1.label.localeCompare(p2.label))

export const guidedSetupImportSourcePluginLookup =
  guidedSetupImportSourcePlugins.reduce(
    (lookup: Record<string, GuidedSetupImportSourcePlugin>, plugin) => {
      lookup[plugin.source] = plugin
      return lookup
    },
    {},
  )
