// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client'
import gql from 'graphql-tag'
import { Observable } from 'rxjs'

import { createApolloClient } from '../client.ts'

import type { TypedDocumentNode } from '@apollo/client'

const SampleDocument: TypedDocumentNode<{ sample: { id: string; title: string } }, { id: string }> =
  gql`
    query sample($id: ID!) {
      sample(id: $id) {
        id
        title
      }
    }
  `

describe('createApolloClient', () => {
  // Apollo answers a cache update with a temporary "cache-first" reobservation. Kept for good, a
  //   query switched back to variables it was already loaded with only showed the stale cached
  //   result and never asked the server again.
  it('keeps watched queries on "cache-and-network" after a cache update', async () => {
    const requestedIds: unknown[] = []

    const client = createApolloClient()

    client.setLink(
      new ApolloLink(
        (operation) =>
          new Observable((observer) => {
            requestedIds.push(operation.variables.id)

            setTimeout(() => {
              observer.next({
                data: {
                  sample: { __typename: 'Sample', id: operation.variables.id, title: 'Server' },
                },
              })
              observer.complete()
            })
          }),
      ),
    )

    const observableQuery = client.watchQuery({ query: SampleDocument, variables: { id: '1' } })
    const subscription = observableQuery.subscribe(() => {})

    await vi.waitFor(() => expect(observableQuery.getCurrentResult().loading).toBe(false))

    client.cache.modify({
      id: client.cache.identify({ __typename: 'Sample', id: '1' }),
      fields: { title: () => 'Changed locally' },
    })

    await vi.waitFor(() =>
      expect(observableQuery.getCurrentResult().data?.sample?.title).toBe('Changed locally'),
    )

    // The way vue-apollo hands over changed variables; `setVariables` would reset the policy itself.
    await observableQuery.reobserve({ variables: { id: '2' } })
    await observableQuery.reobserve({ variables: { id: '1' } })

    await vi.waitFor(() => expect(requestedIds).toEqual(['1', '2', '1']))

    subscription.unsubscribe()
  })
})
