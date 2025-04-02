// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { TicketState } from '#shared/entities/ticket/types.ts'

import CommonTicketStateList from '../CommonTicketStateList.vue'

describe('show tickets', () => {
  it('shows tickets', () => {
    const view = renderComponent(CommonTicketStateList, {
      props: {
        counts: {
          [TicketState.Closed]: 1,
          [TicketState.Open]: 3,
        },
        ticketsLinkQuery: `organization.name: "name"`,
      },
      router: true,
      store: true,
    })

    const links = view.getAllByRole('link')

    expect(links[0]).toHaveAttribute(
      'href',
      '/mobile/search/ticket?search=(state.state_type_id: 1 OR state.state_type_id: 2 OR state.state_type_id: 3 OR state.state_type_id: 4) AND organization.name: "name"',
    )
    expect(links[0]).toHaveTextContent('open')
    expect(links[0]).toHaveTextContent('3')

    expect(links[1]).toHaveAttribute(
      'href',
      '/mobile/search/ticket?search=(state.state_type_id: 5) AND organization.name: "name"',
    )
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
        ticketsLinkQuery: `organization.name: "name"`,
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
