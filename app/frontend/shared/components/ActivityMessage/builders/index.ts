// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ActivityMessageBuilder } from '../types'

const builderModules = import.meta.glob<ActivityMessageBuilder>(
  ['./**/*.ts', '!./**/index.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const activityMessageBuilder = Object.values(builderModules).reduce(
  (builders: Record<string, ActivityMessageBuilder>, builder) => {
    builders[builder.model] = builder
    return builders
  },
  {},
)
