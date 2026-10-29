// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumChannelArea } from '#shared/graphql/types.ts'
import { SYSTEM_USER_ID, SYSTEM_USER_INTERNAL_ID } from '#shared/utils/constants.ts'

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

    expect(view.queryByText('escalation', { exact: false })).not.toBeInTheDocument()
  })

  it('shows a channel alert, if applicable', () => {
    mockPermissions(['ticket.agent'])

    const testDate = new Date()

    const { ticket: currentTicket } = defaultTicket(
      {},
      {
        whatsapp: {
          timestamp_incoming: testDate.setMinutes(testDate.getMinutes() - 30).valueOf() / 1000,
        },
      },
    )

    currentTicket.initialChannel = EnumChannelArea.WhatsAppBusiness

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    const alert = view.getByText(
      'You have a 24 hour window to send WhatsApp messages in this conversation. The customer service window closes in 23 hours.',
    )

    expect(alert).toHaveClass('common-alert-warning')
  })

  it('shows the system customer without name and inactive styling', () => {
    mockPermissions(['ticket.agent'])
    const { ticket: currentTicket } = defaultTicket()

    currentTicket.customer = {
      ...currentTicket.customer,
      id: SYSTEM_USER_ID,
      internalId: SYSTEM_USER_INTERNAL_ID,
      firstname: 'System',
      lastname: '',
      fullname: 'System',
      active: false,
    }
    currentTicket.organization = null

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    const avatar = view.getByRole('img', { name: 'Avatar (System)' })

    expect(avatar).not.toHaveClass('opacity-60')
    expect(view.getByTestId('title-content')).not.toHaveTextContent('System')
  })

  it('shows the organization of the system customer without a separator', () => {
    mockPermissions(['ticket.agent'])
    const { ticket: currentTicket } = defaultTicket()

    currentTicket.customer = {
      ...currentTicket.customer,
      id: SYSTEM_USER_ID,
      internalId: SYSTEM_USER_INTERNAL_ID,
      fullname: 'System',
    }

    const view = renderComponent(TicketDetailViewTitle, {
      props: {
        ticket: currentTicket,
      },
      router: true,
    })

    const title = view.getByTestId('title-content')

    expect(title).toHaveTextContent(currentTicket.organization!.name!)
    expect(title).not.toHaveTextContent('·')
  })
})
