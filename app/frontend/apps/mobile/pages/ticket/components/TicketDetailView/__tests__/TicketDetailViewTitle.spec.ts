// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { defaultTicket } from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'
import TicketDetailViewTitle from '../TicketDetailViewTitle.vue'

describe('TicketDetailViewTitle.vue', () => {
  it('show priority for agent permission', () => {
    mockPermissions(['ticket.agent'])
    const { ticket: currentTicket } = defaultTicket()

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    expect(view.getByText('1 low')).toBeInTheDocument()
  })

  it('does not show priority without agent permission', () => {
    mockPermissions([])
    const { ticket: currentTicket } = defaultTicket()

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    expect(view.queryByText('1 low')).not.toBeInTheDocument()
  })

  it('show escalation for agent permission', () => {
    mockPermissions(['ticket.agent'])
    const { ticket: currentTicket } = defaultTicket()

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    expect(view.getByText('escalation', { exact: false })).toBeInTheDocument()
  })

  it('does not show escalation without agent permission', () => {
    mockPermissions([])
    const { ticket: currentTicket } = defaultTicket()

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    expect(
      view.queryByText('escalation', { exact: false }),
    ).not.toBeInTheDocument()
  })
})
