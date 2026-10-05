// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  ApolloClient,
  ApolloLink,
  execute,
  gql,
  InMemoryCache,
  Observable,
} from '@apollo/client/core'
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'

import trackOperationsLink, { cancelActiveOperations } from '../trackOperations.ts'

import type { DefaultContext, FetchResult } from '@apollo/client/core'

const subscriptionDocument = gql`
  subscription sampleUpdates {
    sampleUpdates {
      id
    }
  }
`

const queryDocument = gql`
  query sample {
    sample {
      id
      name
    }
  }
`

const mutationDocument = gql`
  mutation sampleUpdate {
    sampleUpdate {
      id
    }
  }
`

const setup = () => {
  const teardownSpy = vi.fn()

  // Terminating link which never emits, but records its teardown - which is
  //  what aborts the HTTP request of a query and unsubscribes the Action Cable
  //  channel of a subscription in the application.
  const terminatingLink = new ApolloLink(() => new Observable(() => teardownSpy))

  const link = ApolloLink.from([trackOperationsLink, terminatingLink])

  const start = (query = subscriptionDocument, context?: DefaultContext) =>
    execute(link, { query, context }).subscribe(() => {})

  return { start, teardownSpy }
}

describe('trackOperationsLink', () => {
  afterEach(() => {
    // Make sure no operation of a previous example is left behind.
    cancelActiveOperations()
  })

  it('cancels a running subscription', () => {
    const { start, teardownSpy } = setup()

    start()

    expect(teardownSpy).not.toHaveBeenCalled()

    cancelActiveOperations()

    expect(teardownSpy).toHaveBeenCalledOnce()
  })

  it('cancels all running queries and subscriptions', () => {
    const { start, teardownSpy } = setup()

    start()
    start(queryDocument)
    start(queryDocument)

    cancelActiveOperations()

    expect(teardownSpy).toHaveBeenCalledTimes(3)
  })

  it('keeps subscriptions alive which are marked to survive the logout', () => {
    const { start, teardownSpy } = setup()

    start(subscriptionDocument, { subscription: { keepAliveOnLogout: true } })

    cancelActiveOperations()

    expect(teardownSpy).not.toHaveBeenCalled()
  })

  it('does not cancel mutations', () => {
    const { start, teardownSpy } = setup()

    start(mutationDocument)

    cancelActiveOperations()

    expect(teardownSpy).not.toHaveBeenCalled()
  })

  it('does not cancel an operation which was already stopped', () => {
    const { start, teardownSpy } = setup()

    start().unsubscribe()

    expect(teardownSpy).toHaveBeenCalledOnce()

    cancelActiveOperations()

    expect(teardownSpy).toHaveBeenCalledOnce()
  })

  it('does not cancel an operation twice', () => {
    const { start, teardownSpy } = setup()

    const subscription = start()

    cancelActiveOperations()
    subscription.unsubscribe()

    expect(teardownSpy).toHaveBeenCalledOnce()
  })

  // The Action Cable link unsubscribes its channel via the teardown of the
  //  observable it returns, so make sure that cancelling really reaches it -
  //  otherwise the server would keep the subscription and Action Cable would
  //  execute it again after the reconnect.
  it('unsubscribes the Action Cable channel of a cancelled subscription', () => {
    const unsubscribeSpy = vi.fn()

    const channel = { unsubscribe: unsubscribeSpy, perform: vi.fn() }
    const cable = { subscriptions: { create: vi.fn(() => channel) } }

    const link = ApolloLink.from([
      trackOperationsLink,
      new ActionCableLink({ cable: cable as never }),
    ])

    execute(link, { query: subscriptionDocument }).subscribe(() => {})

    expect(cable.subscriptions.create).toHaveBeenCalledOnce()
    expect(unsubscribeSpy).not.toHaveBeenCalled()

    cancelActiveOperations()

    expect(unsubscribeSpy).toHaveBeenCalledOnce()
  })

  // Clearing the Apollo store cancels a running query only in a following task,
  //  so its result could still land in the emptied cache.
  it('keeps the result of a cancelled query out of the cleared cache', async () => {
    let deliverResult: (result: FetchResult) => void = () => {}

    const terminatingLink = new ApolloLink(
      () =>
        new Observable<FetchResult>((observer) => {
          deliverResult = (result) => {
            observer.next(result)
            observer.complete()
          }
        }),
    )

    const client = new ApolloClient({
      link: ApolloLink.from([trackOperationsLink, terminatingLink]),
      cache: new InMemoryCache(),
    })

    client.watchQuery({ query: queryDocument }).subscribe(() => {})

    await new Promise((resolve) => {
      setTimeout(resolve)
    })

    cancelActiveOperations()

    await client.clearStore()

    deliverResult({ data: { sample: { __typename: 'Sample', id: '1', name: 'Previous session' } } })

    expect(client.cache.extract()).toEqual({})
  })
})
