// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { parseGraphqlId } from '#shared/graphql/utils.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

/**
 * Extracts the internal ID from an entity object.
 * Handles both GraphQL ID strings and direct internalId properties.
 */
export const getInternalId = (item?: { id?: string; internalId?: number }): number | undefined => {
  if (!item) return

  if (item.internalId) return item.internalId

  if (!item.id) return

  return parseGraphqlId(item.id).id
}

/**
 * Extracts internal ID(s) from an entity object or GraphQL connection.
 * Handles both single objects and GraphQL edges format (arrays).
 */
export const extractEntityIds = (
  entityObject: ObjectLike | undefined,
): number | number[] | undefined => {
  if (!entityObject) return undefined

  // Handle GraphQL edges format (arrays)
  if ('edges' in entityObject) {
    return edgesToArray(entityObject)
      .map((item) => getInternalId(item as ObjectLike))
      .filter((id): id is number => id !== undefined)
  }

  // Handle single object
  return getInternalId(entityObject as { id?: string; internalId?: number })
}
