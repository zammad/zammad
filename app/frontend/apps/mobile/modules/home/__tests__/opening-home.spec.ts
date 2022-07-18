// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { OverviewsDocument } from '@shared/entities/ticket/graphql/queries/overviews.api'
import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'
import createMockClient from '@tests/support/mock-apollo-client'
import { mockPermissions } from '@tests/support/mock-permissions'
import { getApiTicketOverviews } from '@tests/support/mocks/ticket-overviews'
import { getTicketOverviewStorage } from '../helpers/ticketOverviewStorage'

describe('home page', () => {
  beforeEach(() => {
    mockAccount({ id: '666' })
    createMockClient([
      {
        operationDocument: OverviewsDocument,
        handler: async () => ({ data: getApiTicketOverviews() }),
      },
    ])
  })

  it('renders ticket overviews based on localStorage', async () => {
    mockPermissions(['ticket.agent', 'ticket.customer'])
    const { saveOverviews } = getTicketOverviewStorage()
    saveOverviews(['3', '2'])

    const view = await visitView('/')

    expect(view.getByIconName('loader')).toBeInTheDocument()
    expect(view.getByRole('link', { name: /Edit/ })).toHaveAttribute(
      'href',
      '/favorite/ticker-overviews/edit',
    )

    const overviews = await view.findAllByText(/^Overview/)

    expect(overviews).toHaveLength(2)
    expect(overviews[0]).toHaveTextContent('Overview 3')
    expect(overviews[1]).toHaveTextContent('Overview 2')
  })

  it('do not show favorite ticket overview section on home without permission', async () => {
    const view = await visitView('/')

    expect(
      view.queryByRole('link', { name: /Edit/ }),
      "doesn't have link when account doesn't have rights",
    ).not.toBeInTheDocument()

    expect(view.queryByText('Ticket Overview')).not.toBeInTheDocument()
  })
})
