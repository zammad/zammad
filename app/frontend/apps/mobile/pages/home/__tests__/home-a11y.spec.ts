// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { TicketOverviewsDocument } from '@shared/entities/ticket/graphql/queries/ticket/overviews.api'
import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'
import createMockClient from '@tests/support/mock-apollo-client'
import { getApiTicketOverviews } from '@tests/support/mocks/ticket-overviews'

describe('testing home a11y', () => {
  beforeEach(() => {
    mockAccount({ id: '666' })
    createMockClient([
      {
        operationDocument: TicketOverviewsDocument,
        handler: async () => ({ data: getApiTicketOverviews() }),
      },
    ])
  })

  it('home screen has no accessibility violations', async () => {
    const view = await visitView('/')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('favorite ticket overviews screen has no accessibility violations', async () => {
    const view = await visitView('/favorite/ticker-overviews/edit')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
