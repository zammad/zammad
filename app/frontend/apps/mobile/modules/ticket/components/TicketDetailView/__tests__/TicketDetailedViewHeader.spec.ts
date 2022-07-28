// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const now = new Date('2020-02-01 00:00:00')
vi.setSystemTime(now)

import { renderComponent } from '@tests/support/components'
import TicketDetailViewHeader from '../TicketDetailViewHeader.vue'

const createdAt = new Date('2020-01-29 00:00:00')

beforeAll(async () => {
  await import('../TicketViewersDialog.vue')
})

describe('tickets zoom header', () => {
  test('has basic information', () => {
    const view = renderComponent(TicketDetailViewHeader, {
      props: {
        ticketId: '123456',
        createdAt: createdAt.toISOString(),
        users: [],
      },
    })

    expect(
      view.getByIconName('arrow-left'),
      'has back icon',
    ).toBeInTheDocument()
    expect(view.getByText('#123456'), 'has ticket id').toBeInTheDocument()
    expect(
      view.getByText('created 3 days ago'),
      'has time ticket was created',
    ).toBeInTheDocument()
  })

  test('has avatars and opens viewers dialog', async () => {
    const view = renderComponent(TicketDetailViewHeader, {
      props: {
        ticketId: '123456',
        createdAt: createdAt.toISOString(),
        users: [{ id: '654321', firstname: 'John', lastname: 'Doe' }],
      },
      dialog: true,
    })

    vi.useRealTimers()

    expect(
      view.getByRole('img', { name: /John Doe/ }),
      'has an avatar of a single user',
    ).toBeInTheDocument()
    expect(
      view.queryByLabelText(/Ticket has \d+ viewers/),
      "doesn't have a counter, since there is only one viewer",
    ).not.toBeInTheDocument()

    await view.rerender({
      users: [
        { id: '654321', firstname: 'Dorothy', lastname: 'Zbornak' },
        { id: '654320', firstname: 'Rose', lastname: 'Nylund' },
        { id: '654329', firstname: 'Blanche', lastname: 'Devereaux' },
        { id: '654322', firstname: 'Sophia', lastname: 'Petrillo' },
      ],
    })

    const counter = view.getByLabelText(/Ticket has 4 viewers/)

    expect(counter, 'has a counter').toBeInTheDocument()
    expect(counter).toHaveTextContent('+3')

    await view.events.click(view.getByTestId('viewers-counter'))

    // TODO assert the same users

    expect(await view.findByText('Editing ticket')).toBeInTheDocument()
    expect(view.getByText('Viewing ticket')).toBeInTheDocument()
    expect(view.getByText('Opened in taskbar')).toBeInTheDocument()
  })
})
