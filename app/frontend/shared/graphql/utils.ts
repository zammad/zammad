// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const isGraphQLId = (id: unknown): id is string => {
  return typeof id === 'string' && id.startsWith('gid://zammad/')
}

export const convertToGraphQLId = (type: string, id: number | string) => {
  return `gid://zammad/${type}/${id}`
}

export const ensureGraphqlId = (type: string, id: number | string): string => {
  if (isGraphQLId(id)) {
    return id
  }

  return convertToGraphQLId(type, id)
}

export const parseGraphqlId = (
  id: string,
): { relation: string; id: number } => {
  const [relation, idString] = id.slice('gid://zammad/'.length).split('/')

  return {
    relation,
    id: parseInt(idString, 10),
  }
}

export const getIdFromGraphQLId = (graphqlId: string) => {
  const parsedGraphqlId = parseGraphqlId(graphqlId)
  return parsedGraphqlId.id
}

export const convertToGraphQLIds = (type: string, ids: (number | string)[]) => {
  return ids.map((id) => convertToGraphQLId(type, id))
}

/**
 * Recursively removes the '__typename' key from the given object and its nested objects/ array.
 *
 * @param {unknown} obj - The input object to clean up.
 * @return {unknown} The cleaned up object without the '__typename' key.
 * @info Used for graphql mutation that need payload with the appollo client added '__typename' key
 */
export const cleanupGraphQLTypename = (obj: unknown): unknown => {
  if (Array.isArray(obj)) {
    return obj.map(cleanupGraphQLTypename)
  } else if (typeof obj === 'object' && obj !== null) {
    const newObj: Record<string, unknown> = {}
    Object.keys(obj as Record<string, unknown>).forEach((key) => {
      if (key !== '__typename') {
        newObj[key] = cleanupGraphQLTypename(
          (obj as Record<string, unknown>)[key],
        )
      }
    })
    return newObj
  }
  return obj
}
