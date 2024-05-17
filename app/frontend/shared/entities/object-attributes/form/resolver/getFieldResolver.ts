// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumObjectManagerObjects,
  ObjectManagerFrontendAttribute,
} from '#shared/graphql/types.ts'

import type FieldResolver from './FieldResolver.ts'
import type {
  FieldResolverClass,
  FieldResolverModule,
} from '../../types/resolver.ts'

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
  attribute: ObjectManagerFrontendAttribute,
): FieldResolver => {
  if (!fieldResolverClasses[attribute.dataType]) {
    throw new Error(
      `No field resolver for type ${attribute.dataType} (${attribute.name})`,
    )
  }

  return new fieldResolverClasses[attribute.dataType](object, attribute)
}

export default getFieldResolver
