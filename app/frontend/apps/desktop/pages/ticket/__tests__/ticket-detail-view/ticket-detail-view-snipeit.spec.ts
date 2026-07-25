// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockTicketExternalReferencesSnipeitAssetListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesSnipeitAssetList.mocks.ts'

describe('Ticket detail view Snipe-IT integration', () => {
  it('displays Snipe-IT integration', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({
      snipeit_integration: true,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).getByRole('button', { name: 'Snipe-IT' })).toBeInTheDocument()
  })

  it('hides Snipe-IT integration when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketExternalReferencesSnipeitAssetListQuery({
      ticketExternalReferencesSnipeitAssetList: [],
    })

    await mockApplicationConfig({
      snipeit_integration: false,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).queryByRole('button', { name: 'Snipe-IT' })).not.toBeInTheDocument()
  })
})
