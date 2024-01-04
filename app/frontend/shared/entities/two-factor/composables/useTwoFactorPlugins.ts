// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import type { TwoFactorPlugin } from '../types.ts'

const pluginsModules = import.meta.glob<TwoFactorPlugin>('../plugins/*.ts', {
  eager: true,
  import: 'default',
})

const pluginsFiles = Object.values(pluginsModules).sort(
  (p1, p2) => p1.order - p2.order,
)

const plugins = keyBy(pluginsFiles, 'name')

export const useTwoFactorPlugins = () => {
  return {
    twoFactorMethods: pluginsFiles,
    twoFactorPlugins: plugins,
  }
}
