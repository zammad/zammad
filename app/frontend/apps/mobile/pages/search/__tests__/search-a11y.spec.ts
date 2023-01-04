// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { visitView } from '@tests/support/components/visitView'
import type { MockGraphQLInstance } from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { waitUntil } from '@tests/support/utils'
import { mockSearchOverview } from '../graphql/mocks/mockSearchOverview'

describe('testing search a11y', () => {
  let mockSearchApi: MockGraphQLInstance

  beforeEach(() => {
    mockSearchApi = mockSearchOverview([])
    mockPermissions(['ticket.agent'])
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/search/ticket?search=welcome')

    await waitUntil(() => mockSearchApi.calls.resolve)

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
