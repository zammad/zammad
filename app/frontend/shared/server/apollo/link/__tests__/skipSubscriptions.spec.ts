// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, execute, gql, Observable } from '@apollo/client/core'

import { browserTabId } from '../../utils/browserTabId.ts'
import skipSubscriptionsLink from '../skipSubscriptions.ts'

import type { DefaultContext } from '@apollo/client/core'

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

    return Observable.of({ data: {} })
  })

  execute(ApolloLink.from([skipSubscriptionsLink, terminatingLink]), {
    query: mutationDocument,
    context,
  }).subscribe(() => {})

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
