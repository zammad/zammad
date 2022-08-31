// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketState } from '@shared/entities/ticket/types'
import { renderComponent } from '@tests/support/components'
import CommonTicketStateList from '../CommonTicketStateList.vue'

describe('show tickets', () => {
  it('shows tickets', () => {
    const view = renderComponent(CommonTicketStateList, {
      props: {
        counts: {
          [TicketState.Closed]: 1,
          [TicketState.Open]: 3,
        },
        ticketsLink: (state: TicketState) => `/tickets?state=${state}`,
      },
      router: true,
      store: true,
    })

    const links = view.getAllByRole('link')

    expect(links[0]).toHaveAttribute('href', '/tickets?state=open')
    expect(links[0]).toHaveTextContent('open')
    expect(links[0]).toHaveTextContent('3')

    expect(links[1]).toHaveAttribute('href', '/tickets?state=closed')
    expect(links[1]).toHaveTextContent('closed')
    expect(links[1]).toHaveTextContent('1')
  })

  it('shows link to create', () => {
    const view = renderComponent(CommonTicketStateList, {
      props: {
        counts: {
          [TicketState.Closed]: 1,
          [TicketState.Open]: 3,
        },
        ticketsLink: (state: TicketState) => `/tickets?state=${state}`,
        createLabel: 'Create ticket',
        createLink: '/tickets/create',
      },
      router: true,
      store: true,
    })

    const createLink = view.getByRole('link', { name: 'Create ticket' })

    expect(createLink).toHaveAttribute('href', '/tickets/create')
  })
})
