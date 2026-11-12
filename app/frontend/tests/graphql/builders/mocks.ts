// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloClient, ApolloLink } from '@apollo/client'
import {
  cloneDeep,
  mergeDeep,
  removeDirectivesFromDocument,
} from '@apollo/client/utilities/internal'
import { provideApolloClient } from '@vue/apollo-composable/compat'
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
import { isMatch, noop } from 'lodash-es'
import { Observable } from 'rxjs'
import { afterEach } from 'vitest'

import { waitForNextTick } from '#tests/support/utils.ts'
import { waitUntil } from '#tests/support/vitest-wrapper.ts'

import createCache from '#shared/server/apollo/cache.ts'
import * as apolloClientModule from '#shared/server/apollo/client.ts'
import type { GraphQLErrorTypes } from '#shared/types/error.ts'
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
  const directiveless = removeDirectivesFromDocument([{ name: 'connection' }], query)
  const stripped = directiveless !== null ? stripNames(directiveless) : null
  return stripped === null ? query : stripped
}

const requestToKey = (query: DocumentNode) => {
  const cached = queryStrings.get(query)
  if (cached) return cached
  const operationNode = query.definitions.find(
    (node) => node.kind === Kind.OPERATION_DEFINITION,
  ) as OperationDefinitionNode
  const operationNameKey = `${operationNode.operation}:${operationNode.name?.value || ''}`
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
      const fragment = fragments.find((fragment) => fragment.name.value === node.name.value)
      if (fragment) {
        fragment.selectionSet.selections.forEach(processNode)
      }
      return
    }

    const fieldName = 'alias' in node && node.alias ? node.alias?.value : node.name!.value
    if (!fieldName) {
      return
    }
    const resultValue = resultData?.[fieldName]
    if ('selectionSet' in node && node.selectionSet) {
      if (Array.isArray(resultValue)) {
        newData[fieldName] = resultValue.map((item) =>
          stripQueryData(node, fragments, item, newData[name]),
        )
      } else {
        newData[fieldName] = stripQueryData(node, fragments, resultValue, newData[name])
      }
    } else {
      newData[fieldName] = resultValue ?? null
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
  return waitUntil(() => {
    try {
      const calls = getGraphQLMockCalls<T>(documentOrOperation, operationName)
      return calls.length && calls
    } catch {
      return false
    }
  })
}

export const mockGraphQLResultWithError = <T extends Record<string, any>>(
  document: DocumentNode,
  message: string,
  extensions: { type: GraphQLErrorTypes },
) => {
  const key = requestToKey(document)
  const error = new GraphQLError(message, {
    extensions,
  })
  const result = { data: null, errors: [error] }
  const calls = mockCalls.get(key) || []
  calls.push({ document, result, variables: {} })
  mockCalls.set(key, calls)
  return {
    waitForCalls: () => waitForGraphQLMockCalls<T>(document),
  }
}

// A defaults function that returns a promise holds the answer back until it settles.
export type MockDefaultsValue<T, V = Record<string, never>> =
  | DeepPartial<T>
  | ((variables: V) => DeepPartial<T> | Promise<DeepPartial<T>>)

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

interface RegisteredSubscriptionHandler {
  variables: Record<string, unknown>
  handler: TestSubscriptionHandler<Record<string, any>>
}

const mockSubscriptionHandlers = new Map<string, RegisteredSubscriptionHandler[]>()

// Two subscriptions of one document can be open at once (e.g. link updates for a ticket and for
//   a knowledge base answer); `variables` picks one, otherwise the last one that is still open wins.
export const getGraphQLSubscriptionHandler = <T extends Record<string, any>>(
  documentOrName: DocumentNode | (keyof T & string),
  variables?: Record<string, unknown>,
) => {
  const key =
    typeof documentOrName === 'string'
      ? getCachedKey('subscription', documentOrName)
      : getCachedKey(documentOrName)

  const registered = mockSubscriptionHandlers.get(key) || []
  const candidates = variables
    ? registered.filter((entry) => isMatch(entry.variables, variables))
    : registered

  const open = candidates.filter((entry) => !entry.handler.closed())

  return (open.at(-1) ?? candidates.at(-1))?.handler as TestSubscriptionHandler<T>
}

afterEach(() => {
  mockCalls.clear()
  mockSubscriptionHandlers.clear()
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
  userDefaults: any,
  definition: OperationDefinitionNode,
  variables: Record<string, any> = {},
): Record<string, any> => {
  if (!variables.input || definition.operation !== OperationTypeNode.MUTATION) return userDefaults
  const inputVariableNode = definition.variableDefinitions?.find((node) => {
    return node.variable.name.value === 'input'
  })
  if (!inputVariableNode) return userDefaults
  const objectInputType = getInputObjectType(inputVariableNode.type)
  if (!objectInputType || !objectInputType.endsWith('Input')) return userDefaults

  const objectType = objectInputType.slice(0, -5)
  const mutationName = definition.name!.value
  const mutationDefinition = getOperationDefinition(definition.operation, mutationName)
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
  request(operation: ApolloLink.Operation): Observable<ApolloLink.Result> {
    const { query, variables } = operation
    const { fetchOptions } = operation.getContext()
    const definition = query.definitions[0]
    if (definition.kind !== Kind.OPERATION_DEFINITION) {
      throw new Error(`Cannot mock a document without an operation: ${print(query)}`)
    }
    const fragments = query.definitions.filter(
      (def) => def.kind === Kind.FRAGMENT_DEFINITION,
    ) as FragmentDefinitionNode[]
    const queryKey = requestToKey(query)
    return new Observable<ApolloLink.Result>((observer) => {
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

      // Like the HTTP link, an aborted request fails instead of answering later.
      const signal: AbortSignal | undefined = fetchOptions?.signal
      const onAbort = (cancel: () => void) => {
        const abort = () => {
          cancel()
          observer.error(signal?.reason)
        }

        if (signal?.aborted) abort()
        else signal?.addEventListener('abort', abort, { once: true })

        return () => signal?.removeEventListener('abort', abort)
      }

      // Apollo Client 3 delivered link results in a later task, and specs rely on
      //  observing the loading state in between - keep that contract.
      const emitLater = (emit: () => void) => {
        let cancelled = false
        const stopListening = onAbort(() => {
          cancelled = true
        })
        queueMicrotask(() => {
          if (!cancelled) emit()
        })
        return () => {
          cancelled = true
          stopListening()
        }
      }

      // Return operation errors if they got set we're assuming one error per operation
      const calls = mockCalls.get(queryKey) || []

      const errorCall = calls.find((call) => call.result.errors)
      if (errorCall) {
        calls.push({ document: query, result: errorCall.result, variables })
        return emitLater(() => {
          observer.next(cloneDeep(errorCall.result))
          observer.complete()
        })
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
        mockSubscriptionHandlers.set(queryKey, [
          ...(mockSubscriptionHandlers.get(queryKey) || []),
          { variables, handler },
        ])

        // Recorded like a query's, so a spec can assert what a subscription was started *with* -
        //   a subscription keyed off the wrong thing delivers nothing and looks like silence.
        calls.push({ document: query, result: { data: null }, variables })
        mockCalls.set(queryKey, calls)

        return noop
      }
      const emitData = (data: unknown) => {
        observer.next(cloneDeep({ data: stripQueryData(definition, fragments, data) }))
        observer.complete()
      }

      try {
        const userDefaults = mockDefaults.get(queryKey)
        const defaultsValue =
          typeof userDefaults === 'function' ? userDefaults(variables) : userDefaults

        // Recorded before the answer, so a spec can wait for the request it is holding back.
        if (defaultsValue instanceof Promise) {
          const call: MockCall = { document: query, result: {}, variables }
          calls.push(call)
          mockCalls.set(queryKey, calls)

          let cancelled = false
          const stopListening = onAbort(() => {
            cancelled = true
          })

          defaultsValue
            .then((value) => {
              if (cancelled) return

              call.result = mockOperation(
                query,
                variables,
                getQueryDefaults(value, definition, variables),
              )
              emitData(call.result)
            })
            .catch((error) => observer.error(error))

          return () => {
            cancelled = true
            stopListening()
          }
        }

        const defaults = getQueryDefaults(defaultsValue, definition, variables)
        const returnResult = mockOperation(query, variables, defaults)
        calls.push({ document: query, result: returnResult, variables })
        mockCalls.set(queryKey, calls)
        return emitLater(() => emitData(returnResult))
      } catch (e) {
        console.error(e)
        throw e
      }
    })
  }
}

// Include both shared and app-specific cache initializer modules.
const cacheInitializerModules: CacheInitializerModules = import.meta.glob(
  '../../../**/server/apollo/cache/initializer/*.ts',
  { eager: true },
)

const createMockClient = () => {
  const link = new MockLink()
  const cache = createCache(cacheInitializerModules)

  const client = new ApolloClient({
    cache,
    link,
    devtools: { enabled: false },
  })
  provideApolloClient(client)
  return client
}

// this enabled automocking - if this file is not imported somehow, fetch request will throw an error
export const mockedApolloClient = createMockClient()

// Not a `vi.mock`: the browser has fetched the client module before this one runs. A spec (or
//   `visitView`) that mocks the module itself has no seam and keeps its own `getApolloClient`.
if ('setApolloClient' in apolloClientModule) {
  apolloClientModule.setApolloClient(mockedApolloClient)
}

// Apollo shares one `watchFragment` observable per fragment and object and tears it down a
//   macrotask after its last subscriber leaves; `clearStore` leaves it in place, so the next test
//   would subscribe to it and get this test's data replayed. Timers may be faked, so drop it directly.
const dropFragmentWatches = () => {
  const cache = mockedApolloClient.cache as unknown as { fragmentWatches: object }
  const Registry = cache.fragmentWatches.constructor as new (weakness: boolean) => object
  cache.fragmentWatches = new Registry(true)
}

afterEach(async () => {
  await mockedApolloClient.clearStore()
  dropFragmentWatches()
})
