// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketDetailViewGql } from './mocks/detail-view.ts'

beforeAll(async () => {
  await import('../components/TicketDetailView/ArticleMetadataDialog.vue')
})

describe('actions inside article context', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  test('opens metadata', async () => {
    const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

    const view = await visitView('/tickets/1', {
      global: {
        stubs: {
          transition: false,
        },
      },
    })

    await waitUntilTicketLoaded()

    const contextTriggers = view.getAllByRole('button', {
      name: 'Article actions',
    })

    await view.events.click(contextTriggers[0])
    await view.events.click(view.getByText('Show meta data'))

    expect(view.getByText('Meta Data')).toBeInTheDocument()
    expect(view.getByRole('region', { name: 'Created' })).toHaveTextContent(
      /2022-01-29 00:00/,
    )

    // content is tested inside unit test
  })
})
