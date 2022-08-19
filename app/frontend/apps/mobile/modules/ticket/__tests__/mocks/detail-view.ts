// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketState } from '@shared/entities/ticket/types'
import type { TicketArticlesQuery, TicketQuery } from '@shared/graphql/types'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { nullableMock, waitUntil } from '@tests/support/utils'

import { TicketDocument } from '../../graphql/queries/ticket.api'

import { TicketArticlesDocument } from '../../graphql/queries/ticket/articles.api'
import { TicketUpdatesDocument } from '../../graphql/subscriptions/ticketUpdates.api'

const ticketDate = new Date(2022, 0, 29, 0, 0, 0, 0)

export const defaultTicket = () =>
  nullableMock<TicketQuery>({
    ticket: {
      __typename: 'Ticket',
      id: '1fs432fdsfsg3qr32d',
      internalId: 1,
      number: '610001',
      title: 'Test Ticket View',
      createdAt: ticketDate.toISOString(),
      updatedAt: ticketDate.toISOString(),
      owner: {
        __typename: 'User',
        id: 'abc12sf123ad2',
        firstname: 'Max',
        lastname: 'Mustermann',
      },
      customer: {
        __typename: 'User',
        id: 'fdsf214fse12d',
        firstname: 'John',
        lastname: 'Doe',
        fullname: 'John Doe',
      },
      organization: {
        __typename: 'Organization',
        name: 'Zammad Foundation',
      },
      state: {
        __typename: 'TicketState',
        id: 'open',
        name: 'open',
        stateType: {
          __typename: 'TicketStateType',
          name: TicketState.Open,
        },
      },
      group: {
        __typename: 'Group',
        id: 'Users',
        name: 'Users',
      },
      priority: {
        __typename: 'TicketPriority',
        id: 'low',
        name: 'low',
        uiColor: 'low',
        defaultCreate: false,
      },
    },
  })

const address = {
  __typename: 'AddressesField' as const,
  parsed: null,
  raw: '',
}

const nullableArticle = {
  __typename: 'TicketArticle' as const,
  references: null,
  inReplyTo: null,
  messageIdMd5: null,
  messageId: null,
  subject: null,
}

export const defaultArticles = (): TicketArticlesQuery =>
  nullableMock({
    description: {
      __typename: 'TicketArticleConnection',
      edges: [
        {
          __typename: 'TicketArticleEdge',
          node: {
            ...nullableArticle,
            id: '1fs432fczfsg3qr32d',
            internalId: 1,
            createdAt: ticketDate.toISOString(),
            to: address,
            replyTo: address,
            cc: address,
            from: address,
            createdBy: {
              __typename: 'User',
              id: 'fdsf214fse12d',
              firstname: 'John',
              lastname: 'Doe',
              fullname: 'John Doe',
            },
            internal: false,
            body: '<p>Body <b>of a test ticket</b></p>',
            sender: {
              __typename: 'TicketArticleType',
              name: 'Customer',
            },
            type: {
              __typename: 'TicketArticleType',
              name: 'article',
            },
            contentType: 'text/html',
            attachments: [
              // should not be visible
              {
                __typename: 'StoredFile',
                internalId: 66,
                name: 'not-visible-attachment.png',
                type: 'image/png',
                size: 0,
                preferences: {
                  'original-format': true,
                },
              },
            ],
            preferences: {},
          },
        },
      ],
    },
    articles: {
      __typename: 'TicketArticleConnection',
      totalCount: 3,
      edges: [
        {
          __typename: 'TicketArticleEdge',
          node: {
            ...nullableArticle,
            id: '1fs432fdsfsg3qr32f',
            internalId: 2,
            to: address,
            replyTo: address,
            cc: address,
            from: address,
            createdAt: new Date(2022, 0, 30, 0, 0, 0, 0).toISOString(),
            createdBy: {
              __typename: 'User',
              id: 'dsvvr32532fs',
              firstname: 'Albert',
              lastname: 'Einstein',
              fullname: 'Albert Einstein',
            },
            internal: false,
            body: '<p>energy equals power times time</p>',
            sender: {
              __typename: 'TicketArticleType',
              name: 'Agent',
            },
            type: {
              __typename: 'TicketArticleType',
              name: 'article',
            },
            attachments: [],
            preferences: {},
            contentType: 'text/html',
          },
          cursor: 'MH',
        },
        {
          __typename: 'TicketArticleEdge',
          node: {
            ...nullableArticle,
            id: '1fs432fdsfsg3qr30f',
            internalId: 3,
            to: address,
            replyTo: address,
            cc: address,
            from: address,
            createdAt: new Date(2022, 0, 30, 10, 0, 0, 0).toISOString(),
            createdBy: {
              __typename: 'User',
              id: 'fsfy345343f',
              firstname: 'Monkey',
              lastname: 'Brain',
              fullname: 'Monkey Brain',
            },
            internal: true,
            body: '<p>only agents can see this haha</p>',
            sender: {
              __typename: 'TicketArticleType',
              name: 'Agent',
            },
            type: {
              __typename: 'TicketArticleType',
              name: 'article',
            },
            contentType: 'text/html',
            attachments: [],
            preferences: {},
          },
          cursor: 'MI',
        },
      ],
      pageInfo: {
        __typename: 'PageInfo',
        hasPreviousPage: false,
        startCursor: 'MH',
      },
    },
  })

export const mockTicketDetailViewGql = () => {
  mockPermissions(['ticket.agent'])

  const ticket = defaultTicket()

  const mockApiTicket = mockGraphQLApi(TicketDocument).willResolve(ticket)
  const mockApiArticles = mockGraphQLApi(TicketArticlesDocument).willResolve(
    defaultArticles(),
  )
  const mockTicketSubscription = mockGraphQLSubscription(TicketUpdatesDocument)

  const waitUntilTicketLoaded = async () => {
    await waitUntil(
      () => mockApiTicket.calls.resolve && mockApiArticles.calls.resolve,
    )
  }

  return {
    ticket: ticket.ticket,
    mockApiArticles,
    mockApiTicket,
    mockTicketSubscription,
    waitUntilTicketLoaded,
  }
}
