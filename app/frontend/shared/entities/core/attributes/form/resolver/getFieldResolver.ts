// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import type { FieldResolverClass, FieldResolverModule } from '../../types/resolver.ts'
import type { EntityAttribute } from '../../types/store.ts'
import type { FieldResolver } from './FieldResolver.ts'

// fallow-ignore-file circular-dependency -- fallow lets this glob match the specs in fields/__tests__, Vite does not.
const fieldResolverModules = import.meta.glob<FieldResolverModule>(
  ['./fields/*.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

const fieldResolverClasses: Record<string, FieldResolverClass> = {}

Object.entries(fieldResolverModules).forEach(([, resolverModule]) => {
  fieldResolverClasses[resolverModule.type] = resolverModule.resolver
})

const getFieldResolver = (
  object: EnumObjectManagerObjects,
  attribute: EntityAttribute,
): FieldResolver => {
  if (!fieldResolverClasses[attribute.dataType]) {
    throw new Error(`No field resolver for type ${attribute.dataType} (${attribute.name})`)
  }

  return new fieldResolverClasses[attribute.dataType](object, attribute)
}

export default getFieldResolver
