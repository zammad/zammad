// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
import { provideApolloClient } from '@vue/apollo-composable'
import { visit, print } from 'graphql'
import {
  Kind,
  type DocumentNode,
  OperationTypeNode,
  GraphQLError,
  type DefinitionNode,
  type FieldNode,
  type OperationDefinitionNode,
  type TypeNode,
  type SelectionNode,
  type FragmentDefinitionNode,
} from 'graphql'
import { noop } from 'lodash-es'

import { waitForNextTick } from '#tests/support/utils.ts'

import createCache from '#shared/server/apollo/cache.ts'
import type { CacheInitializerModules } from '#shared/types/server/apollo/client.ts'
import type { DeepPartial, DeepRequired } from '#shared/types/utils.ts'

import {
  getFieldData,
  getObjectDefinition,
  getOperationDefinition,
  mockOperation,
  validateOperationVariables,
} from './index.ts'

interface MockCall<T = any> {
  document: DocumentNode
  result: T
  variables: Record<string, any>
}

const mockDefaults = new Map<string, any>()
const mockCalls = new Map<string, MockCall[]>()
const queryStrings = new WeakMap<DocumentNode, string>()

// mutation:login will return query string for mutation login
const namesToQueryKeys = new Map<string, string>()

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
  const operationNode = query.definitions.find(
    (node) => node.kind === Kind.OPERATION_DEFINITION,
  ) as OperationDefinitionNode
  const operationNameKey = `${operationNode.operation}:${
    operationNode.name?.value || ''
  }`
  const normalized = normalize(query)
  const queryString = query && print(normalized)
  const stringified = JSON.stringify({ query: queryString })
  queryStrings.set(query, stringified)
  namesToQueryKeys.set(operationNameKey, stringified)
  return stringified
}

const stripQueryData = (
  definition: DefinitionNode | FieldNode,
  fragments: FragmentDefinitionNode[],
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
  // eslint-disable-next-line sonarjs/cognitive-complexity
  const processNode = (node: SelectionNode) => {
    if (node.kind === Kind.INLINE_FRAGMENT) {
      const condition = node.typeCondition
      if (!condition || condition.kind !== Kind.NAMED_TYPE) {
        throw new Error('Unknown type condition!')
      }
      const typename = condition.name.value
      if (resultData.__typename === typename) {
        node.selectionSet.selections.forEach(processNode)
      }
      return
    }
    if (node.kind === Kind.FRAGMENT_SPREAD) {
      const fragment = fragments.find(
        (fragment) => fragment.name.value === node.name.value,
      )
      if (fragment) {
        fragment.selectionSet.selections.forEach(processNode)
      }
      return
    }

    const fieldName =
      'alias' in node && node.alias ? node.alias?.value : node.name!.value
    if (!fieldName) {
      return
    }
    const resultValue = resultData[fieldName]
    if ('selectionSet' in node && node.selectionSet) {
      if (Array.isArray(resultValue)) {
        newData[fieldName] = resultValue.map((item) =>
          stripQueryData(node, fragments, item, newData[name]),
        )
      } else {
        newData[fieldName] = stripQueryData(
          node,
          fragments,
          resultValue,
          newData[name],
        )
      }
    } else {
      newData[fieldName] = resultValue
    }
  }
  definition.selectionSet?.selections.forEach(processNode)

  return newData
}

type OperationType = 'query' | 'mutation' | 'subscription'

const getCachedKey = (
  documentOrOperation: DocumentNode | OperationType,
  operationName?: string,
) => {
  const key =
    typeof documentOrOperation === 'string'
      ? namesToQueryKeys.get(`${documentOrOperation}:${operationName}`)
      : requestToKey(documentOrOperation)
  if (!key) {
    throw new Error(
      `Cannot find key for ${documentOrOperation}:${operationName}. This happens if query was not executed yet or if it was not mocked.`,
    )
  }
  return key
}

export const getGraphQLMockCalls = <T>(
  documentOrOperation: DocumentNode | OperationType,
  operationName?: keyof T & string,
): MockCall<DeepRequired<T>>[] => {
  return mockCalls.get(getCachedKey(documentOrOperation, operationName)) || []
}

export const waitForGraphQLMockCalls = <T>(
  documentOrOperation: DocumentNode | OperationType,
  operationName?: keyof T & string,
): Promise<MockCall<DeepRequired<T>>[]> => {
  return vi.waitUntil(() => {
    try {
      const calls = getGraphQLMockCalls<T>(documentOrOperation, operationName)
      return calls.length && calls
    } catch {
      return false
    }
  })
}

export type MockDefaultsValue<T, V = Record<string, never>> =
  | DeepPartial<T>
  | ((variables: V) => DeepPartial<T>)

export const mockGraphQLResult = <
  T extends Record<string, any>,
  V extends Record<string, any> = Record<string, never>,
>(
  document: DocumentNode,
  defaults: MockDefaultsValue<T, V>,
) => {
  const key = requestToKey(document)
  mockDefaults.set(key, defaults)
  return {
    updateDefaults: (defaults: MockDefaultsValue<T, V>) => {
      mockDefaults.set(key, defaults)
    },
    waitForCalls: () => waitForGraphQLMockCalls<T>(document),
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
  documentOrName: DocumentNode | (keyof T & string),
) => {
  const key =
    typeof documentOrName === 'string'
      ? getCachedKey('subscription', documentOrName)
      : getCachedKey(documentOrName)

  return mockSubscriptionHanlders.get(key) as TestSubscriptionHandler<T>
}

afterEach(() => {
  mockCalls.clear()
  mockSubscriptionHanlders.clear()
  mockDefaults.clear()
  mockCalls.clear()
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
  variables: Record<string, any> = {},
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
    const fragments = query.definitions.filter(
      (def) => def.kind === Kind.FRAGMENT_DEFINITION,
    ) as FragmentDefinitionNode[]
    const queryKey = requestToKey(query)
    return new Observable((observer) => {
      const { operation } = definition

      try {
        validateOperationVariables(definition, variables)
      } catch (err) {
        if (operation === OperationTypeNode.QUERY) {
          // queries eat the errors, but we want to see them
          console.error(err)
        }
        throw err
      }

      if (operation === OperationTypeNode.SUBSCRIPTION) {
        const handler: TestSubscriptionHandler = {
          async trigger(defaults) {
            const resultValue = mockOperation(query, variables, defaults)
            const data = stripQueryData(definition, fragments, resultValue)
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
      try {
        const defaults = getQueryDefaults(queryKey, definition, variables)
        const returnResult = mockOperation(query, variables, defaults)
        const result = { data: returnResult }
        const calls = mockCalls.get(queryKey) || []
        calls.push({ document: query, result: result.data, variables })
        mockCalls.set(queryKey, calls)
        observer.next(
          cloneDeep({
            data: stripQueryData(definition, fragments, result.data),
          }),
        )
        observer.complete()
      } catch (e) {
        console.error(e)
        throw e
      }

      return noop
    })
  }
}

const cacheInitializerModules: CacheInitializerModules = import.meta.glob(
  '../../../shared/server/apollo/cache/initializer/*.ts',
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

// this enabled automocking - if this file is not imported somehow, fetch request will throw an error
export const mockedApolloClient = createMockClient()

vi.mock('#shared/server/apollo/client.ts', () => {
  return {
    clearApolloClientStore: async () => {
      await mockedApolloClient.clearStore()
    },
    getApolloClient: () => {
      return mockedApolloClient
    },
  }
})

afterEach(() => {
  mockedApolloClient.clearStore()
})
