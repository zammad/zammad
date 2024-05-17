// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { render } from '@testing-library/vue'
import {
  useLazyQuery,
  useMutation,
  useSubscription,
} from '@vue/apollo-composable'

import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'

import {
  getGraphQLMockCalls,
  getGraphQLSubscriptionHandler,
  type TestSubscriptionHandler,
} from '../mocks.ts'

import type { DocumentNode, OperationVariables } from '@apollo/client/core'
import type { OptionsParameter } from '@vue/apollo-composable/dist/useQuery'

interface EnhancedQueryHandler<R, V extends OperationVariables>
  extends QueryHandler<R, V> {
  getMockedData: () => { data: R }
}

interface EnhancedMutationHandler<R, V extends OperationVariables>
  extends MutationHandler<R, V> {
  getMockedData: () => { data: R }
}

interface EnhancedSubscriptionHandler<
  R extends Record<string, any>,
  V extends OperationVariables,
> extends SubscriptionHandler<R, V> {
  getTestSubscriptionHandler: () => TestSubscriptionHandler<R>
}

const disposables = new Set<() => void>()

const getHandler = (document: DocumentNode, cb: () => any) => {
  let handler: any
  const component = render({
    render() {
      return null
    },
    setup() {
      handler = cb()
      handler.getMockedData = () => {
        const { result } = getGraphQLMockCalls(document).at(-1) as any
        return { data: result }
      }
    },
  })
  disposables.add(() => component.unmount())
  return handler!
}

export const getQueryHandler = <
  R,
  V extends OperationVariables = OperationVariables,
>(
  document: DocumentNode,
  variables?: V,
  options?: OptionsParameter<R, V>,
) => {
  return getHandler(
    document,
    () => new QueryHandler(useLazyQuery(document, variables, options)),
  ) as EnhancedQueryHandler<R, V>
}

export const getMutationHandler = <
  R,
  V extends OperationVariables = OperationVariables,
>(
  document: DocumentNode,
) => {
  return getHandler(
    document,
    () => new MutationHandler(useMutation(document)),
  ) as EnhancedMutationHandler<R, V>
}

export const getSubscriptionHandler = <
  R extends Record<string, any>,
  V extends OperationVariables = OperationVariables,
>(
  document: DocumentNode,
  variables: V,
) => {
  const handler = getHandler(
    document,
    () => new SubscriptionHandler(useSubscription<R, V>(document, variables)),
  ) as EnhancedSubscriptionHandler<R, V>
  handler.getTestSubscriptionHandler = () => {
    return getGraphQLSubscriptionHandler(document)
  }
  return handler
}

beforeEach(() => {
  disposables.forEach((dispose) => dispose())
  disposables.clear()
})
