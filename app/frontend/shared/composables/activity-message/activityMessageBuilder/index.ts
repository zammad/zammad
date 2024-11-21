// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ActivityMessageBuilder } from './types.ts'

const builderModules = import.meta.glob<ActivityMessageBuilder>(
  ['./builders/*.ts'],
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
