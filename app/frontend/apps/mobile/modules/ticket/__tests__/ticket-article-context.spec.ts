// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'
import { mockTicketDetailViewGql } from './mocks/detail-view'

beforeAll(async () => {
  await import('../components/TicketDetailView/ArticleMetadataDialog.vue')
})

describe('actions inside article context', () => {
  test('opens metadata', async () => {
    const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

    const view = await visitView('/tickets/1')

    await waitUntilTicketLoaded()

    const contextTriggers = view.getAllByRole('button', {
      name: 'Article actions',
    })

    await view.events.click(contextTriggers[0])
    await view.events.click(view.getByText('Show meta data'))

    expect(view.getByText('Meta Data')).toBeInTheDocument()
    expect(view.getByTitle('Sent')).toHaveTextContent(/2022-01-29 00:00/)

    // content is tested inside unit test
  })
})
