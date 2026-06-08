// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityModule } from '#desktop/components/CommonSimpleEntityList/types.ts'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

const modules = import.meta.glob<EntityModule>(['./*.ts', '!./index.ts'], {
  eager: true,
  import: 'default',
})

const entityModules = Object.entries(modules).reduce(
  (acc, [_, module]) => {
    acc[module.type] = module
    return acc
  },
  {} as Record<EntityType, (typeof modules)[EntityType]>,
)

export default entityModules
