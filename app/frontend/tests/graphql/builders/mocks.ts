// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  Kind,
  type DocumentNode,
  OperationTypeNode,
  GraphQLError,
  type DefinitionNode,
  type FieldNode,
  type OperationDefinitionNode,
  type TypeNode,
} from 'graphql'
import { waitForNextTick } from '#tests/support/utils.ts'
import {
  ApolloClient,
  ApolloLink,
  Observable,
  type FetchResult,
  type Operation,
} from '@apollo/client/core'
import {
  cloneDeep,
  mergeDeep,
  removeConnectionDirectiveFromDocument,
} from '@apollo/client/utilities'
import { visit, print } from 'graphql'
import createCache from '#shared/server/apollo/cache.ts'
import type { CacheInitializerModules } from '#shared/types/server/apollo/client.ts'
import { noop } from 'lodash-es'
import { provideApolloClient } from '@vue/apollo-composable'
import type { DeepPartial } from '#shared/types/utils.ts'
import {
  getFieldData,
  getObjectDefinition,
  getOperationDefinition,
  mockOperation,
} from './index.ts'

const mockDefaults = new Map<string, any>()
const mockResults = new Map<string, any>()
const queryStrings = new WeakMap<DocumentNode, string>()

const stripNames = (query: DocumentNode) => {
  return visit(query, {
    Field: {
      enter(node) {
        return node.name.value === '__typename' ? null : undefined
      },
    },
  })
}

const normalize = (query: DocumentNode) => {
  const directiveless = removeConnectionDirectiveFromDocument(query)
  const stripped = directiveless !== null ? stripNames(directiveless) : null
  return stripped === null ? query : stripped
}

const requestToKey = (query: DocumentNode) => {
  const cached = queryStrings.get(query)
  if (cached) return cached
  const normalized = normalize(query)
  const queryString = query && print(normalized)
  const stringified = JSON.stringify({ query: queryString })
  queryStrings.set(query, stringified)
  return stringified
}

const stripQueryData = (
  definition: DefinitionNode | FieldNode,
  resultData: any,
  newData: any = {},
  // eslint-disable-next-line sonarjs/cognitive-complexity
) => {
  if (!('selectionSet' in definition) || !definition.selectionSet) {
    return newData
  }

  if (typeof newData !== 'object' || newData === null) {
    return newData
  }

  if (typeof newData !== 'object' || resultData === null) {
    return resultData
  }

  const name = definition.name!.value
  definition.selectionSet?.selections.forEach((node) => {
    if (node.kind === Kind.INLINE_FRAGMENT) return
    const fieldName =
      'alias' in node && node.alias ? node.alias?.value : node.name!.value
    if (!fieldName) {
      return
    }
    const resultValue = resultData[fieldName]
    if ('selectionSet' in node && node.selectionSet) {
      if (Array.isArray(resultValue)) {
        newData[fieldName] = resultValue.map((item) =>
          stripQueryData(node, item, newData[name]),
        )
      } else {
        newData[fieldName] = stripQueryData(node, resultValue, newData[name])
      }
    } else {
      newData[fieldName] = resultValue
    }
  })

  return newData
}

// Returns the full query result, not the object that was returned in the operation
// So, if you didn't ask for a field, but it's defined in the type schema, this field WILL be in the object
export const getGraphQLResult = <T>(document: DocumentNode): { data: T } => {
  return mockResults.get(requestToKey(document))
}

export const mockGraphQLResult = <T extends Record<string, any>>(
  document: DocumentNode,
  defaults:
    | DeepPartial<T>
    | ((variables?: Record<string, unknown>) => DeepPartial<T>),
) => {
  const key = requestToKey(document)
  mockDefaults.set(key, defaults)
  return {
    getResult: getGraphQLResult,
    updateDefaults: (defaults: DeepPartial<T>) => {
      mockDefaults.set(key, defaults)
    },
  }
}

export interface TestSubscriptionHandler<T extends Record<string, any> = any> {
  /** Ensure that some data will be returned based on the schema */
  trigger(defaults?: DeepPartial<T>): Promise<T>
  triggerErrors(errors: GraphQLError[]): Promise<void>
  error(values?: unknown): void
  complete(): void
  closed(): boolean
}

const mockSubscriptionHanlders = new Map<
  string,
  TestSubscriptionHandler<Record<string, any>>
>()
export const getGraphQLSubscriptionHandler = <T extends Record<string, any>>(
  document: DocumentNode,
) => {
  return mockSubscriptionHanlders.get(
    requestToKey(document),
  ) as TestSubscriptionHandler<T>
}

afterEach(() => {
  mockResults.clear()
  mockSubscriptionHanlders.clear()
  mockDefaults.clear()
})

const getInputObjectType = (variableNode: TypeNode): string | null => {
  if (variableNode.kind === Kind.NON_NULL_TYPE) {
    return getInputObjectType(variableNode.type)
  }
  if (variableNode.kind === Kind.LIST_TYPE) {
    return null
  }
  return variableNode.name.value
}

// assume "$input" value is the default, but test defaults will take precedence
const getQueryDefaults = (
  requestKey: string,
  definition: OperationDefinitionNode,
  variables: Record<string, any>,
): Record<string, any> => {
  let userDefaults = mockDefaults.get(requestKey)
  if (typeof userDefaults === 'function') {
    userDefaults = userDefaults(variables)
  }
  if (!variables.input || definition.operation !== OperationTypeNode.MUTATION)
    return userDefaults
  const inputVariableNode = definition.variableDefinitions?.find((node) => {
    return node.variable.name.value === 'input'
  })
  if (!inputVariableNode) return userDefaults
  const objectInputType = getInputObjectType(inputVariableNode.type)
  if (!objectInputType || !objectInputType.endsWith('Input'))
    return userDefaults

  const objectType = objectInputType.slice(0, -5)
  const mutationName = definition.name!.value
  const mutationDefinition = getOperationDefinition(
    definition.operation,
    mutationName,
  )
  // expect object to be in the first level, otherwise we might update the wrong object
  const payloadDefinition = getObjectDefinition(mutationDefinition.type.name)
  const sameTypeField = payloadDefinition.fields?.find((node) => {
    return getFieldData(node.type).name === objectType
  })

  if (!sameTypeField) return userDefaults
  const inputDefaults = {
    [mutationName]: {
      [sameTypeField.name]: variables.input,
    },
  }
  return mergeDeep(inputDefaults, userDefaults || {})
}

// This link automatically:
//  - respects "$typeId" variables, doesn't respect "$typeInternalId" because we need to move away from them
//  - mocks queries, respects defaults
//  - mocks mutations, respects defaults, but also looks for "$input" variable and updates the object if it's inside the first level
//  - mocks result for subscriptions, respects defaults
class MockLink extends ApolloLink {
  // eslint-disable-next-line class-methods-use-this
  request(operation: Operation): Observable<FetchResult> | null {
    const { query, variables } = operation
    const definition = query.definitions[0]
    if (definition.kind !== Kind.OPERATION_DEFINITION) {
      return null
    }
    const queryKey = requestToKey(query)
    return new Observable((observer) => {
      const { operation } = definition
      if (operation === OperationTypeNode.SUBSCRIPTION) {
        const handler: TestSubscriptionHandler = {
          async trigger(defaults) {
            const resultValue = mockOperation(query, variables, defaults)
            const data = stripQueryData(definition, resultValue)
            observer.next({ data })
            await waitForNextTick(true)
            return resultValue
          },
          async triggerErrors(errors) {
            observer.next({ errors })
            await waitForNextTick(true)
          },
          error: observer.error.bind(observer),
          complete: observer.complete.bind(observer),
          closed: () => observer.closed,
        }
        mockSubscriptionHanlders.set(queryKey, handler)
        return noop
      }
      const defaults = getQueryDefaults(queryKey, definition, variables)
      const returnResult = mockOperation(query, variables, defaults)
      let result = { data: returnResult }
      mockResults.set(queryKey, result)
      if (operation === OperationTypeNode.MUTATION) {
        result = { data: stripQueryData(definition, result.data) }
      }
      observer.next(cloneDeep(result))
      observer.complete()
      return noop
    })
  }
}

const cacheInitializerModules: CacheInitializerModules = import.meta.glob(
  '../../../../mobile/server/apollo/cache/initializer/*.ts',
  { eager: true },
)

const createMockClient = () => {
  const link = new MockLink()
  const cache = createCache(cacheInitializerModules)
  const client = new ApolloClient({
    cache,
    link,
  })
  provideApolloClient(client)
  return client
}

export const mockedApolloClient = createMockClient()

afterEach(() => {
  mockedApolloClient.clearStore()
})
