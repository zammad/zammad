// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

const parents = new WeakMap()

const generatedIds = new Map<string, number>()

afterEach(() => {
  generatedIds.clear()
})

export const getNodeParent = (node: any): any => {
  return parents.get(node)
}

export const setNodeParent = (node: any, parent: any): void => {
  parents.set(node, parent)
}

export const hasNodeParent = (node: any): boolean => {
  return parents.has(node)
}

export const generateGraphqlMockId = (parent: any): string => {
  const typename = parent.__typename
  const id = generatedIds.get(typename) || 0
  const newId = id + 1
  if (newId >= 100) {
    console.error(parent)
    throw new Error(
      `Detected a loop. Too many generated ids for ${typename} inside a single test.`,
    )
  }
  generatedIds.set(typename, newId)
  return convertToGraphQLId(typename, newId)
}

export const updateGeneratedIds = (typename: string, id: number): void => {
  const currentId = generatedIds.get(typename)
  if (currentId === undefined || id > currentId) {
    generatedIds.set(typename, id)
  }
}
