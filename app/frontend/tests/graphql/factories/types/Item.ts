// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { Item } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { getUnionPossibleTypeNames } from '../../builders/index.ts'

import type { ResolversMeta } from '../../builders/index.ts'

// Always generate items based on the searched entity, so an auto-mocked search returns what the
//   operation actually asked for. Without this, the mocker picks a random member of the `Item`
//   union, and an item whose type the operation has no inline fragment for gets stripped down to
//   its bare `__typename` (`detailSearch` with `onlyIn: User` would hand a user list an item
//   without an `id`).
export default (_parent: any, _defaults: any, meta: ResolversMeta): DeepPartial<Item> => {
  const possibleTypeNames = getUnionPossibleTypeNames('Item')

  // `EnumSearchableModels` carries the Rails class name, so derive the GraphQL type name the same
  //   way graphql-ruby does: `KnowledgeBase__Answer__Translation` -> `KnowledgeBaseAnswerTranslation`.
  const { onlyIn } = meta.variables
  const searchedTypeName = typeof onlyIn === 'string' ? onlyIn.replaceAll('__', '') : undefined

  // Never return a falsy value here: the mocker's list branch would build `[undefined, …]`, which
  //   is still truthy, and generating a value for the bare `Item` union then throws.
  // The fallback picks a type per item, where the mocker would pick one for the whole list. That
  //   only affects operations passing the entity as a literal instead of a variable (`quickSearch`).
  return {
    __typename: (searchedTypeName && possibleTypeNames.includes(searchedTypeName)
      ? searchedTypeName
      : faker.helpers.arrayElement(possibleTypeNames)) as NonNullable<Item['__typename']>,
  }
}
