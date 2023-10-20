// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import type { DocumentNode, OperationVariables } from '@apollo/client/core'
import { render } from '@testing-library/vue'
import {
  useLazyQuery,
  useMutation,
  useSubscription,
} from '@vue/apollo-composable'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import type { OptionsParameter } from '@vue/apollo-composable/dist/useQuery'
import {
  getGraphQLResult,
  getGraphQLSubscriptionHandler,
  type TestSubscriptionHandler,
} from '../mocks.ts'

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
        return getGraphQLResult(document)
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
