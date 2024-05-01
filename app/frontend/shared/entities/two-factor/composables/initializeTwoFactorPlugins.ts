// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import type {
  TwoFactorConfigurationOptions,
  TwoFactorPlugin,
} from '../types.ts'

const pluginsModules = import.meta.glob<TwoFactorPlugin>('../plugins/*.ts', {
  eager: true,
  import: 'default',
})

export const twoFactorPluginsFiles = Object.values(pluginsModules).sort(
  (p1, p2) => p1.order - p2.order,
)

export const initializeTwoFactorPlugins = (
  twoFactorConfigurationPlugins: Record<
    EnumTwoFactorAuthenticationMethod,
    TwoFactorConfigurationOptions
  >,
) => {
  twoFactorPluginsFiles.forEach((plugin) => {
    if (twoFactorConfigurationPlugins[plugin.name]) {
      plugin.configurationOptions = twoFactorConfigurationPlugins[plugin.name]
    }
  })
}
