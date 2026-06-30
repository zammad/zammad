// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { InMemoryCache } from '@apollo/client/cache'
import gql from 'graphql-tag'

import registerRedirect from '../registerRedirect.ts'

import type { DocumentNode } from 'graphql'

// The redirect lets a single-entity query (e.g. the ticket detail view)
// resolve from a normalized entry already in the cache, without a network
// round-trip. The field name must match the query root field (`ticket`),
// while the id is read from its `<field>Id` argument.
const cases = [
  { field: 'ticket', typename: 'Ticket' },
  { field: 'user', typename: 'User' },
  { field: 'organization', typename: 'Organization' },
] as const

const detailQuery = (field: string): DocumentNode => gql`
  query ${field}($${field}Id: ID!) {
    ${field}(${field}Id: $${field}Id) {
      __typename
      id
      name
    }
  }
`

describe('registerRedirect', () => {
  it.each(cases)(
    'redirects a $field query to an already-cached normalized entry',
    ({ field, typename }) => {
      const cache = new InMemoryCache(registerRedirect({}, field, typename))
      const id = `gid://zammad/${typename}/42`
      cache.restore({
        [cache.identify({ __typename: typename, id })!]: {
          __typename: typename,
          id,
          name: 'Cached entry',
        },
      })

      const result = cache.readQuery<Record<string, { id: string; name: string }>>({
        query: detailQuery(field),
        variables: { [`${field}Id`]: id },
      })

      expect(result?.[field]).toMatchObject({ id, name: 'Cached entry' })
    },
  )

  it.each(cases)(
    'does not resolve a $field query when the entity is not cached',
    ({ field, typename }) => {
      const cache = new InMemoryCache(registerRedirect({}, field, typename))

      const result = cache.readQuery({
        query: detailQuery(field),
        variables: { [`${field}Id`]: `gid://zammad/${typename}/404` },
      })

      expect(result).toBeNull()
      // Apollo warns about the dangling reference to the uncached entity.
      vi.mocked(console.warn).mockClear()
    },
  )
})
