// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const now = new Date('2020-02-01 00:00:00')
vi.setSystemTime(now)

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { EnumTaskbarApp } from '@shared/graphql/types'
import { renderComponent } from '@tests/support/components'
import TicketDetailViewHeader from '../TicketDetailViewHeader.vue'

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
      },
    })

    expect(
      view.getByIconName('mobile-chevron-left'),
      'has back icon',
    ).toBeInTheDocument()
    expect(
      view.getByText(`#${ticket.number}`),
      'has ticket id',
    ).toBeInTheDocument()
    expect(
      view.getByText('created 3 days ago'),
      'has time ticket was created',
    ).toBeInTheDocument()
  })

  test('has avatars and opens viewers dialog', async () => {
    const view = renderComponent(TicketDetailViewHeader, {
      props: {
        ticket,
        liveUserList: [
          {
            editing: false,
            user: { id: '654321', firstname: 'John', lastname: 'Doe' },
            lastInteraction: new Date().toISOString(),
            apps: [EnumTaskbarApp.Desktop],
          },
        ],
      },
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
          editing: false,
          user: { id: '654321', firstname: 'John', lastname: 'Doe' },
          lastInteraction: new Date().toISOString(),
          apps: [EnumTaskbarApp.Desktop],
        },
        {
          editing: false,
          user: { id: '123123', firstname: 'Rose', lastname: 'Nylund' },
          lastInteraction: new Date().toISOString(),
          apps: [EnumTaskbarApp.Desktop],
        },
        {
          editing: false,
          user: { id: '524523', firstname: 'Sophia', lastname: 'Petrillo' },
          lastInteraction: new Date('2019-01-01 00:00:00').toISOString(),
          apps: [EnumTaskbarApp.Mobile],
        },
      ],
    })

    const counter = view.getByLabelText(/Ticket has 3 viewers/)

    expect(counter, 'has a counter').toBeInTheDocument()
    expect(counter).toHaveTextContent('+2')

    await view.events.click(view.getByTestId('viewers-counter'))

    expect(await view.getByText('Viewing ticket')).toBeInTheDocument()
    expect(view.getByText('Opened in tabs')).toBeInTheDocument()
  })
})
