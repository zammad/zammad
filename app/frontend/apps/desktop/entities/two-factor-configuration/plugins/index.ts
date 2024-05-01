// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  TwoFactorConfigurationOptions,
  TwoFactorConfigurationPlugin,
} from '#shared/entities/two-factor/types.ts'

const pluginsModules = import.meta.glob<TwoFactorConfigurationPlugin>(
  ['./**/*.ts', '!./**/index.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const twoFactorConfigurationPlugins = Object.values(pluginsModules)

export const twoFactorConfigurationPluginLookup =
  twoFactorConfigurationPlugins.reduce(
    (lookup: Record<string, TwoFactorConfigurationOptions>, plugin) => {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { name, ...options } = plugin // remove not needed name from options.
      lookup[plugin.name] = options
      return lookup
    },
    {},
  )
