// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, execute, gql, Observable } from '@apollo/client/core'
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink'

import trackSubscriptionsLink, { cancelActiveSubscriptions } from '../trackSubscriptions.ts'

import type { DefaultContext } from '@apollo/client/core'

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
    }
  }
`

const setup = () => {
  const teardownSpy = vi.fn()

  // Terminating link which never emits, but records its teardown - which is
  //  what the Action Cable link uses to unsubscribe its channel.
  const terminatingLink = new ApolloLink(() => new Observable(() => teardownSpy))

  const link = ApolloLink.from([trackSubscriptionsLink, terminatingLink])

  const start = (query = subscriptionDocument, context?: DefaultContext) =>
    execute(link, { query, context }).subscribe(() => {})

  return { start, teardownSpy }
}

describe('trackSubscriptionsLink', () => {
  afterEach(() => {
    // Make sure no subscription of a previous example is left behind.
    cancelActiveSubscriptions()
  })

  it('cancels a running subscription', () => {
    const { start, teardownSpy } = setup()

    start()

    expect(teardownSpy).not.toHaveBeenCalled()

    cancelActiveSubscriptions()

    expect(teardownSpy).toHaveBeenCalledOnce()
  })

  it('cancels all running subscriptions', () => {
    const { start, teardownSpy } = setup()

    start()
    start()
    start()

    cancelActiveSubscriptions()

    expect(teardownSpy).toHaveBeenCalledTimes(3)
  })

  it('keeps subscriptions alive which are marked to survive the logout', () => {
    const { start, teardownSpy } = setup()

    start(subscriptionDocument, { subscription: { keepAliveOnLogout: true } })

    cancelActiveSubscriptions()

    expect(teardownSpy).not.toHaveBeenCalled()
  })

  it('does not cancel queries', () => {
    const { start, teardownSpy } = setup()

    start(queryDocument)

    cancelActiveSubscriptions()

    expect(teardownSpy).not.toHaveBeenCalled()
  })

  it('does not cancel a subscription which was already stopped', () => {
    const { start, teardownSpy } = setup()

    start().unsubscribe()

    expect(teardownSpy).toHaveBeenCalledOnce()

    cancelActiveSubscriptions()

    expect(teardownSpy).toHaveBeenCalledOnce()
  })

  it('does not cancel a subscription twice', () => {
    const { start, teardownSpy } = setup()

    const subscription = start()

    cancelActiveSubscriptions()
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
      trackSubscriptionsLink,
      new ActionCableLink({ cable: cable as never }),
    ])

    execute(link, { query: subscriptionDocument }).subscribe(() => {})

    expect(cable.subscriptions.create).toHaveBeenCalledOnce()
    expect(unsubscribeSpy).not.toHaveBeenCalled()

    cancelActiveSubscriptions()

    expect(unsubscribeSpy).toHaveBeenCalledOnce()
  })
})
