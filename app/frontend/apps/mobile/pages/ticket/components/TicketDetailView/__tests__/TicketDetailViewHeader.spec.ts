// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTaskbarApp } from '#shared/graphql/types.ts'

import { defaultTicket } from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'

import TicketDetailViewHeader from '../TicketDetailViewHeader.vue'

vi.hoisted(() => {
  const now = new Date('2020-02-01 00:00:00')
  vi.setSystemTime(now)
})

const createdAt = new Date('2020-01-29 00:00:00')

beforeAll(async () => {
  await import('../TicketViewersDialog.vue')
})

const { ticket } = defaultTicket()
ticket.createdAt = createdAt.toISOString()

describe('tickets zoom header', () => {
  test('has basic information', () => {
    const view = renderComponent(TicketDetailViewHeader, {
      props: {
        ticket,
        users: [],
        refetchingTicket: false,
      },
      router: true,
    })

    expect(view.getByIconName('home'), 'has home icon').toBeInTheDocument()
    expect(view.getByText(`#${ticket.number}`), 'has ticket id').toBeInTheDocument()
    expect(view.getByText('created 3 days ago'), 'has time ticket was created').toBeInTheDocument()
  })

  test('has avatars and opens viewers dialog', async () => {
    const view = renderComponent(TicketDetailViewHeader, {
      props: {
        ticket: { ...ticket, aiAgentRunning: false },
        refetchingTicket: false,
        liveUserList: [
          {
            user: { id: '654321', firstname: 'John', lastname: 'Doe' },
            app: EnumTaskbarApp.Desktop,
            lastInteraction: new Date().toISOString(),
            editing: false,
          },
        ],
      },
      router: true,
      dialog: true,
    })

    expect(
      view.getByRole('img', { name: /John Doe/ }),
      'has an avatar of a single user',
    ).toBeInTheDocument()
    expect(
      view.queryByLabelText(/Ticket has \d+ viewers/),
      "doesn't have a counter, since there is only one viewer",
    ).not.toBeInTheDocument()

    await view.rerender({
      liveUserList: [
        {
          user: { id: '654321', firstname: 'John', lastname: 'Doe' },
          app: EnumTaskbarApp.Desktop,
          lastInteraction: new Date().toISOString(),
          editing: false,
        },
        {
          user: { id: '123123', firstname: 'Rose', lastname: 'Nylund' },
          app: EnumTaskbarApp.Desktop,
          lastInteraction: new Date().toISOString(),
          editing: false,
        },
        {
          user: { id: '524523', firstname: 'Sophia', lastname: 'Petrillo' },
          app: EnumTaskbarApp.Mobile,
          lastInteraction: new Date('2019-01-01 00:00:00').toISOString(),
          editing: false,
        },
      ],
    })

    const counter = view.getByLabelText(/Ticket has 3 viewers/)

    expect(counter, 'has a counter').toBeInTheDocument()
    expect(counter).toHaveTextContent('+2')

    await view.events.click(view.getByRole('button', { name: 'Show ticket viewers' }))

    expect(view.getByText('Viewing ticket')).toBeInTheDocument()
    expect(view.getByText('Opened in tabs')).toBeInTheDocument()
  })

  describe('AI Agent', () => {
    it('displays AI agent running', () => {
      const view = renderComponent(TicketDetailViewHeader, {
        props: {
          ticket: { ...ticket, aiAgentRunning: true },
          refetchingTicket: false,
          liveUserList: [],
        },
        router: true,
      })

      expect(view.getByLabelText('AI Agent')).toBeInTheDocument()
    })
  })
})
