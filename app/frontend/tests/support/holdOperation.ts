// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, Observable, type FetchResult, type OperationVariables } from '@apollo/client'
import { onTestFinished } from 'vitest'

import { mockedApolloClient } from '#tests/graphql/builders/mocks.ts'

/**
 * Holds back every matching operation until the returned function is called - what a slow
 *   answer looks like. The mocked link answers within a tick otherwise, which leaves no state
 *   in between to look at. The original link is restored when the test finishes.
 */
export const holdOperation = (
  operationName: string,
  matchesVariables: (variables: OperationVariables) => boolean = () => true,
) => {
  const { link } = mockedApolloClient

  let release = () => {}
  const released = new Promise<void>((resolve) => {
    release = resolve
  })

  mockedApolloClient.setLink(
    new ApolloLink((operation, forward) => {
      if (operation.operationName !== operationName || !matchesVariables(operation.variables))
        return forward(operation)

      return new Observable<FetchResult>((observer) => {
        let subscription: { unsubscribe: () => void } | undefined

        released.then(() => {
          subscription = forward(operation).subscribe(observer)
        })

        return () => subscription?.unsubscribe()
      })
    }).concat(link),
  )

  onTestFinished(() => mockedApolloClient.setLink(link))

  return release
}
