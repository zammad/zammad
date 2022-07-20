// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 0, 0, 0, 0)
vi.setSystemTime(now)

import { TicketState } from '@shared/entities/ticket/types'
import type { TicketQuery } from '@shared/graphql/types'
import { getAllByRole } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { flushPromises } from '@vue/test-utils'
import { mock } from 'vitest-mock-extended'
import { TicketDocument } from '../graphql/queries/ticket.api'

const ticketDate = new Date(2022, 0, 29, 0, 0, 0, 0)

const ticket = mock<TicketQuery>({
  ticket: {
    id: '1fs432fdsfsg3qr32d',
    internalId: 1,
    number: '610001',
    createdAt: ticketDate.toISOString(),
    title: 'Test Ticket View',
    owner: {
      firstname: 'Max',
      lastname: 'Mustermann',
    },
    customer: {
      id: 'fdsf214fse12d',
      firstname: 'John',
      lastname: 'Doe',
      fullname: 'John Doe',
    },
    organization: {
      name: 'Zammad Foundation',
    },
    state: {
      name: 'open',
      stateType: {
        name: TicketState.Open,
      },
    },
    priority: {
      name: 'low',
      uiColor: 'low',
      defaultCreate: false,
    },
    articles: {
      edges: [
        {
          node: {
            id: '1fs432fdsfsg3qr32d',
            createdAt: ticketDate.toISOString(),
            createdBy: {
              id: 'fdsf214fse12d',
              firstname: 'John',
              lastname: 'Doe',
            },
            internal: false,
            body: '<p>Body <b>of a test ticket</b></p>',
            sender: {
              name: 'Customer',
            },
          },
        },
        {
          node: {
            id: '1fs432fdsfsg3qr32f',
            createdAt: new Date(2022, 0, 30, 0, 0, 0, 0).toISOString(),
            createdBy: {
              id: 'dsvvr32532fs',
              firstname: 'Albert',
              lastname: 'Einstein',
            },
            internal: false,
            body: '<p>energy equals power times time</p>',
            sender: {
              name: 'Agent',
            },
          },
        },
        {
          node: {
            id: '1fs432fdsfsg3qr30f',
            createdAt: new Date(2022, 0, 30, 10, 0, 0, 0).toISOString(),
            createdBy: {
              id: 'fsfy345343f',
              firstname: 'Monkey',
              lastname: 'Brain',
            },
            internal: true,
            body: '<p>only agents can see this haha</p>',
            sender: {
              name: 'Agent',
            },
          },
        },
      ],
    },
  },
})

test('statics inside ticket zoom view', async () => {
  const mockApiTicket = mockGraphQLApi(TicketDocument).willResolve(ticket)

  const view = await visitView('/tickets/1')

  expect(view.getByTestId('loader-list')).toBeInTheDocument()
  expect(view.getByTestId('loader-title')).toBeInTheDocument()
  expect(view.getByTestId('loader-header')).toBeInTheDocument()

  await waitUntil(() => mockApiTicket.spies.resolve.mock.calls.length > 0)

  const header = view.getByTestId('header-content')

  expect(header).toHaveTextContent('#610001')
  expect(header).toHaveTextContent('created 3 days ago')

  const titleElement = view.getByTestId('title-content')

  expect(titleElement).toHaveTextContent('Test Ticket View')
  expect(titleElement, 'has customer avatar').toHaveTextContent('JD')

  const articlesElement = view.getByRole('group', { name: 'Articles' })

  const times = getAllByRole(articlesElement, 'time')

  expect(times).toHaveLength(2)
  expect(times[0]).toHaveTextContent('2022-01-29')
  expect(times[1]).toHaveTextContent('2022-01-30')

  const comments = view.getAllByRole('comment')

  // everything else for article is testes inside ArticleBubble
  expect(comments).toHaveLength(3)

  // customer article
  expect(comments[0]).toHaveClass('flex-row-reverse')
  expect(comments[0]).toHaveTextContent('John')
  expect(comments[0]).toHaveTextContent('Body of a test ticket')

  // agent public comment
  expect(comments[1]).not.toHaveClass('flex-row-reverse')
  expect(comments[1]).toHaveTextContent('Albert')
  expect(comments[1]).toHaveTextContent('energy equals power times time')

  // agent internal comment
  expect(comments[2]).not.toHaveClass('flex-row-reverse')
  expect(comments[2]).toHaveTextContent('Monkey')
  expect(comments[2]).toHaveTextContent('only agents can see this haha')

  expect(view.getByRole('button', { name: 'Add reply' })).toBeInTheDocument()
})

test('can refresh data by pulling up', async () => {
  const mockApiTicket = mockGraphQLApi(TicketDocument).willResolve(ticket)

  const view = await visitView('/tickets/1')

  await waitUntil(() => mockApiTicket.spies.resolve.mock.calls.length > 0)

  const articlesElement = view.getByRole('group', { name: 'Articles' })

  const startEvent = new TouchEvent('touchstart', {
    touches: [{ clientY: 300 } as Touch],
  })

  articlesElement.dispatchEvent(startEvent)

  const moveEvent = new TouchEvent('touchmove', {
    touches: [{ clientY: 100 } as Touch],
  })

  Object.defineProperty(document.documentElement, 'scrollHeight', {
    value: 200,
  })
  Object.defineProperty(document.documentElement, 'scrollTop', {
    value: 0,
  })
  Object.defineProperty(document.documentElement, 'clientHeight', {
    value: 200,
  })

  articlesElement.dispatchEvent(moveEvent)

  await flushPromises()

  expect(view.getByIconName('arrow-down')).toHaveStyle({
    transform: 'translateY(22px) rotate(180deg)',
  })

  const touchEnd = new TouchEvent('touchend')
  articlesElement.dispatchEvent(touchEnd)

  await flushPromises()

  expect(view.getByIconName('loader')).toBeInTheDocument()

  // TODO test api call
})

test("shows error, if can't find ticket", async () => {
  mockGraphQLApi(TicketDocument).willFailWithError([
    { message: 'The ticket 9866 could not be found', extensions: {} },
  ])

  const view = await visitView('/tickets/9866')

  expect(
    await view.findByText('The ticket 9866 could not be found'),
  ).toBeInTheDocument()
})

test('show article context on click', async () => {
  const mockApiTicket = mockGraphQLApi(TicketDocument).willResolve(ticket)

  const view = await visitView('/tickets/1')

  await waitUntil(() => mockApiTicket.spies.resolve.mock.calls.length > 0)

  vi.useRealTimers()

  const contextTriggers = view.getAllByRole('button', {
    name: 'Article actions',
  })

  expect(contextTriggers).toHaveLength(3)

  await view.events.click(contextTriggers[0])

  expect(view.getByText('Make internal')).toBeInTheDocument()
  expect(view.getByText('Reply')).toBeInTheDocument()

  // TODO actions itself should be tested when reply will be implemented
})
