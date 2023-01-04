// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 0, 0, 0, 0)
vi.setSystemTime(now)

import { ApolloError } from '@apollo/client/errors'
import { getAllByTestId } from '@testing-library/vue'
import { getTestRouter } from '@tests/support/components/renderComponent'
import { visitView } from '@tests/support/components/visitView'
import createMockClient from '@tests/support/mock-apollo-client'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { nullableMock, waitUntil } from '@tests/support/utils'
import { flushPromises } from '@vue/test-utils'
import { TicketDocument } from '../graphql/queries/ticket.api'
import { TicketArticlesDocument } from '../graphql/queries/ticket/articles.api'
import { TicketUpdatesDocument } from '../graphql/subscriptions/ticketUpdates.api'
import {
  defaultArticles,
  defaultTicket,
  mockTicketDetailViewGql,
} from './mocks/detail-view'

beforeEach(() => {
  mockPermissions(['ticket.agent'])
})

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

  expect(view.getByIconName('mobile-arrow-down')).toHaveStyle({
    transform: 'translateY(22px) rotate(180deg)',
  })

  const touchEnd = new TouchEvent('touchend')
  articlesElement.dispatchEvent(touchEnd)

  await flushPromises()

  expect(view.getAllByIconName('mobile-loading')).not.toHaveLength(0)

  // TODO test api call
})

test("redirects to error page, if can't find ticket", async () => {
  const { calls } = mockGraphQLApi(TicketDocument).willFailWithError([
    { message: 'The ticket 9866 could not be found', extensions: {} },
  ])
  mockGraphQLApi(TicketArticlesDocument).willFailWithError([
    { message: 'The ticket 9866 could not be found', extensions: {} },
  ])
  mockGraphQLSubscription(TicketUpdatesDocument).error(
    new ApolloError({ errorMessage: "Couldn't find Ticket with 'id'=9866" }),
  )

  await visitView('/tickets/9866')

  await waitUntil(() => calls.error > 0)
  await flushPromises()

  const router = getTestRouter()
  expect(router.replace).toHaveBeenCalledWith({
    name: 'Error',
    query: {
      redirect: '1',
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
    data: {
      ticketUpdates: {
        __typename: 'TicketUpdatesPayload',
        ticket: nullableMock({ ...ticket, title: 'Some New Title' }),
      },
    },
  })

  expect(view.getByText('Some New Title')).toBeInTheDocument()
})

test('can load more articles', async () => {
  mockApplicationConfig({
    ticket_articles_min: 1,
  })

  const { description, articles } = defaultArticles()

  const [article1, article2] = articles.edges

  const articlesHandler = vi.fn(async (variables: any) => {
    if (!variables.loadDescription) {
      return {
        data: {
          description: null,
          articles: {
            __typename: 'TicketArticleConnection',
            totalCount: 3,
            edges: [article2],
            pageInfo: {
              __typename: 'PageInfo',
              hasPreviousPage: false,
              startCursor: '',
            },
          },
        },
      }
    }
    return {
      data: {
        description,
        articles: {
          __typename: 'TicketArticleConnection',
          totalCount: 3,
          edges: [article1],
          pageInfo: {
            __typename: 'PageInfo',
            hasPreviousPage: true,
            startCursor: article1.cursor,
          },
        },
      },
    }
  })

  mockGraphQLApi(TicketDocument).willResolve(defaultTicket())
  mockGraphQLSubscription(TicketUpdatesDocument)
  createMockClient([
    {
      operationDocument: TicketArticlesDocument,
      handler: articlesHandler,
    },
  ])

  const view = await visitView('/tickets/1')

  const comments = await view.findAllByRole('comment')

  expect(comments).toHaveLength(2)

  vi.useRealTimers()

  await view.events.click(view.getByText('load 1 more'))

  expect(view.getAllByRole('comment')).toHaveLength(3)
})
