// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import type {
  FieldResolverClass,
  FieldResolverModule,
} from '../../types/resolver'
import type FieldResolver from './FieldResolver'

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
  attribute: ObjectManagerFrontendAttribute,
): FieldResolver => {
  if (!fieldResolverClasses[attribute.dataType]) {
    throw new Error(
      `No field resolver for type ${attribute.dataType} (${attribute.name})`,
    )
  }

  return new fieldResolverClasses[attribute.dataType](attribute)
}

export default getFieldResolver
