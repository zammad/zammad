// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockTicketExternalReferencesIdoitObjectListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectList.mocks.ts'

describe('Ticket detail view i-doit integration', () => {
  it('displays i-doit integration', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      idoit_integration: true,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).getByRole('button', { name: 'i-doit' }),
    ).toBeInTheDocument()
  })

  it('hides i-doit integration when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketExternalReferencesIdoitObjectListQuery({
      ticketExternalReferencesIdoitObjectList: [],
    })

    await mockApplicationConfig({
      idoit_integration: false,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(
      within(sidebar).queryByRole('button', { name: 'i-doit' }),
    ).not.toBeInTheDocument()
  })
})
