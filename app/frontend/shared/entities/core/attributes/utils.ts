// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttributeValue } from '#shared/graphql/types.ts'

import type { PartialDeep } from 'type-fest'

export const flattenObjectAttributeValues = <T = ObjectAttributeValue['value']>(
  objectAttributeValues?: Array<PartialDeep<ObjectAttributeValue>> | null,
): Record<string, T> => {
  if (!objectAttributeValues?.length) return {}

  return objectAttributeValues.reduce((acc: Record<string, T>, cur) => {
    const attributeName = cur.attribute?.name
    if (!attributeName) return acc

    acc[attributeName] = cur.value as T
    return acc
  }, {})
}
