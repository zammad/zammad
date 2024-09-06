// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByTestId } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'

import { getTicketOverviewStorage } from '#mobile/entities/ticket/helpers/ticketOverviewStorage.ts'

describe('home page', () => {
  beforeEach(() => {
    mockUserCurrent({ id: '666' })
    mockTicketOverviews()
  })

  it('renders ticket overviews based on localStorage', async () => {
    mockPermissions(['ticket.agent', 'ticket.customer'])
    const { saveOverviews } = getTicketOverviewStorage()
    saveOverviews(['3', '2'])

    const view = await visitView('/')

    expect(view.getByRole('link', { name: /Edit/ })).toHaveAttribute(
      'href',
      '/mobile/favorite/ticket-overviews/edit',
    )

    const overviews = await view.findAllByText(/^Overview/)

    expect(overviews).toHaveLength(2)
    expect(overviews[0]).toHaveTextContent('Overview 3')
    expect(overviews[1]).toHaveTextContent('Overview 2')

    const overviewLinks = await view.findAllByTestId('section-menu-link')
    const lastOverview = overviewLinks.at(-1)
    expect(lastOverview).toHaveTextContent('Overview 2')

    if (lastOverview) {
      const overviewCount = getByTestId(
        lastOverview,
        'section-menu-information',
      )
      expect(overviewCount).toHaveTextContent('2')
    }
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
