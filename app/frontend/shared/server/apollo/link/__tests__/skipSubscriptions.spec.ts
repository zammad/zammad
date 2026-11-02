// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloClient, ApolloLink, execute, gql, InMemoryCache } from '@apollo/client'
import { of } from 'rxjs'

import { browserTabId } from '../../utils/browserTabId.ts'
import skipSubscriptionsLink from '../skipSubscriptions.ts'

import type { DefaultContext } from '@apollo/client'

// Apollo Client 4 executes a link only on behalf of a client.
const executionContext = {
  client: new ApolloClient({ cache: new InMemoryCache(), link: ApolloLink.empty() }),
}

const mutationDocument = gql`
  mutation sampleUpdate {
    sampleUpdate {
      id
    }
  }
`

const sendAndCaptureHeaders = (context?: DefaultContext) => {
  let sentContext: DefaultContext | undefined

  const terminatingLink = new ApolloLink((operation) => {
    sentContext = operation.getContext()

    return of({ data: {} })
  })

  execute(
    ApolloLink.from([skipSubscriptionsLink, terminatingLink]),
    { query: mutationDocument, context },
    executionContext,
  ).subscribe(() => {})

  return sentContext?.headers
}

describe('skipSubscriptionsLink', () => {
  it('sends the browser tab and the subscriptions to skip', () => {
    expect(
      sendAndCaptureHeaders({
        headers: { 'X-CSRF-Token': 'token' },
        skipSubscriptions: ['userCurrentTaskbarItemStateUpdates', 'ticketUpdates'],
      }),
    ).toEqual({
      'X-CSRF-Token': 'token',
      'X-Zammad-Browser-Tab-Id': browserTabId,
      'X-Zammad-Skip-Subscriptions': 'userCurrentTaskbarItemStateUpdates,ticketUpdates',
    })
  })

  it('sends nothing without subscriptions to skip', () => {
    expect(sendAndCaptureHeaders({ skipSubscriptions: [] })).toBeUndefined()
  })
})
