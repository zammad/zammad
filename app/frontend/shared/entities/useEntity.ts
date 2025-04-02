// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import type { EntityObject } from '#shared/types/entity.ts'

export type EntityName = string | EnumObjectManagerObjects

export interface EntityPlugin<T = EntityObject> {
  name: EntityName
  display: (object: T) => string
}

const entityModules: Record<string, EntityPlugin> = import.meta.glob(
  ['./*/entity.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const entities = Object.values(entityModules)
export const entitiesByName = keyBy(entities, 'name')

export const useEntity = (entity: EntityName) => {
  // TODO: only log or really an error?
  if (!entitiesByName[entity]) {
    throw new Error(`Entity "${entity}" not found`)
  }

  return entitiesByName[entity]
}
