// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketState } from '@shared/entities/ticket/types'
import type { TicketArticlesQuery, TicketQuery } from '@shared/graphql/types'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { waitUntil } from '@tests/support/utils'

import { mock } from 'vitest-mock-extended'
import { TicketDocument } from '../../graphql/queries/ticket.api'

import { TicketArticlesDocument } from '../../graphql/queries/ticket/articles.api'

const ticketDate = new Date(2022, 0, 29, 0, 0, 0, 0)

export const defaultTicket = mock<TicketQuery>({
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
  },
})

const address = {
  parsed: null,
  raw: '',
}

export const defaultArticles = mock<TicketArticlesQuery>({
  ticketArticles: {
    totalCount: 3,
    edges: [
      {
        node: {
          id: '1fs432fdsfsg3qr32d',
          internalId: 1,
          createdAt: ticketDate.toISOString(),
          to: address,
          replyTo: address,
          cc: address,
          from: address,
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
          type: {
            name: 'article',
          },
          contentType: 'text/html',
        },
        cursor: 'Mg',
      },
      {
        node: {
          id: '1fs432fdsfsg3qr32f',
          internalId: 2,
          to: address,
          replyTo: address,
          cc: address,
          from: address,
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
          type: {
            name: 'article',
          },
          contentType: 'text/html',
        },
        cursor: 'MH',
      },
      {
        node: {
          id: '1fs432fdsfsg3qr30f',
          internalId: 3,
          to: address,
          replyTo: address,
          cc: address,
          from: address,
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
          type: {
            name: 'article',
          },
          contentType: 'text/html',
        },
        cursor: 'MI',
      },
    ],
    pageInfo: {
      hasNextPage: false,
      endCursor: '',
    },
  },
})

export const mockTicketDetailvViewGql = () => {
  mockPermissions(['admin.*'])

  const mockApiTicket =
    mockGraphQLApi(TicketDocument).willResolve(defaultTicket)
  const mockApiArticles = mockGraphQLApi(TicketArticlesDocument).willResolve(
    defaultArticles,
  )

  const waitUntillTickesLoaded = async () => {
    await waitUntil(
      () => mockApiTicket.calls.resolve && mockApiArticles.calls.resolve,
    )
  }

  return {
    mockApiArticles,
    mockApiTicket,
    waitUntillTickesLoaded,
  }
}
