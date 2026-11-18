// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockTicketExternalReferencesIdoitUpObjectListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitUpObjectList.mocks.ts'

describe('Ticket detail view i-doit up integration', () => {
  it('displays i-doit up integration', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      idoit_up_integration: true,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).getByRole('button', { name: 'i-doit up' })).toBeInTheDocument()
  })

  it('hides i-doit up integration when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketExternalReferencesIdoitUpObjectListQuery({
      ticketExternalReferencesIdoitUpObjectList: [],
    })

    await mockApplicationConfig({
      idoit_up_integration: false,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).queryByRole('button', { name: 'i-doit up' })).not.toBeInTheDocument()
  })
})
