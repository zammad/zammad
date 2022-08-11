// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 0, 0, 0, 0)
vi.setSystemTime(now)

import { ErrorStatusCodes } from '@shared/types/error'
import { getAllByTestId } from '@testing-library/vue'
import { getTestRouter } from '@tests/support/components/renderComponent'
import { visitView } from '@tests/support/components/visitView'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { flushPromises } from '@vue/test-utils'
import { mock } from 'vitest-mock-extended'
import { TicketDocument } from '../graphql/queries/ticket.api'
import { mockTicketDetailViewGql } from './mocks/detail-view'

test('statics inside ticket zoom view', async () => {
  const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

  const view = await visitView('/tickets/1')

  expect(view.getByTestId('loader-list')).toBeInTheDocument()
  expect(view.getByTestId('loader-title')).toBeInTheDocument()
  expect(view.getByTestId('loader-header')).toBeInTheDocument()

  await waitUntilTicketLoaded()

  const header = view.getByTestId('header-content')

  expect(header).toHaveTextContent('#610001')
  expect(header).toHaveTextContent('created 3 days ago')

  const titleElement = view.getByTestId('title-content')

  expect(titleElement).toHaveTextContent('Test Ticket View')
  expect(titleElement, 'has customer avatar').toHaveTextContent('JD')

  const articlesElement = view.getByRole('group', { name: 'Articles' })

  const times = getAllByTestId(articlesElement, 'date-time-absolute')

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

  expect(
    view.queryByText('not-visible-attachment.png'),
    'filters original-format attachments',
  ).not.toBeInTheDocument()
})

test('can refresh data by pulling up', async () => {
  const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

  const view = await visitView('/tickets/1')

  await waitUntilTicketLoaded()

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

test("redirects to error page, if can't find ticket", async () => {
  const { calls } = mockGraphQLApi(TicketDocument).willFailWithError([
    { message: 'The ticket 9866 could not be found', extensions: {} },
  ])

  await visitView('/tickets/9866')

  await waitUntil(() => calls.error > 0)
  await flushPromises()

  const router = getTestRouter()
  expect(router.replace).toHaveBeenCalledWith({
    name: 'Error',
    params: {
      statusCode: ErrorStatusCodes.Forbidden,
      message: 'Sorry, but you have insufficient rights to open this page.',
    },
  })
})

test('show article context on click', async () => {
  const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

  const view = await visitView('/tickets/1')

  await waitUntilTicketLoaded()

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

test('change content on subscription', async () => {
  const { waitUntilTicketLoaded, mockTicketSubscription, ticket } =
    mockTicketDetailViewGql()

  const view = await visitView('/tickets/1')

  await waitUntilTicketLoaded()

  expect(view.getByText(ticket.title)).toBeInTheDocument()

  await mockTicketSubscription.next({
    data: mock({
      ticketUpdates: { ticket: mock({ ...ticket, title: 'Some New Title' }) },
    }),
  })

  expect(view.getByText('Some New Title')).toBeInTheDocument()
})
