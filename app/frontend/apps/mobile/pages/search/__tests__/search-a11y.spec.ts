// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import type { MockGraphQLInstance } from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { mockSearchOverview } from '../graphql/mocks/mockSearchOverview.ts'

describe('testing search a11y', () => {
  let mockSearchApi: MockGraphQLInstance

  beforeEach(() => {
    mockSearchApi = mockSearchOverview({ totalCount: 0, items: [] })
    mockPermissions(['ticket.agent'])
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/search/ticket?search=welcome')

    await waitUntil(() => mockSearchApi.calls.resolve)

    expect(view.container).toBeAccessible()
  })
})
