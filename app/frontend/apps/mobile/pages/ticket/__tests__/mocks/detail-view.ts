// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeStore } from '#tests/support/components/initializeStore.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import type { ExtendedIMockSubscription } from '#tests/support/mock-graphql-api.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { nullableMock, waitUntil } from '#tests/support/utils.ts'

import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import { mockOnlineNotificationSeenGql } from '#shared/composables/__tests__/mocks/online-notification.ts'
import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import { TicketArticlesDocument } from '#shared/entities/ticket/graphql/queries/ticket/articles.api.ts'
import { TicketDocument } from '#shared/entities/ticket/graphql/queries/ticket.api.ts'
import { TicketArticleUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import { TicketLiveUserUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketLiveUserUpdates.api.ts'
import { TicketUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.api.ts'
import type { TicketView } from '#shared/entities/ticket/types.ts'
import { TicketState } from '#shared/entities/ticket/types.ts'
import {
  type TicketArticlesQuery,
  type TicketLiveUserDeletePayload,
  type TicketLiveUserUpsertPayload,
  type TicketWithMentionLimitQuery,
  type PolicyTicket,
  EnumTicketStateColorCode,
  EnumTicketArticleSenderName,
  type TicketQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import {
  ticketObjectAttributes,
  ticketArticleObjectAttributes,
} from '#mobile/entities/ticket/__tests__/mocks/ticket-mocks.ts'
import { TicketWithMentionLimitDocument } from '#mobile/entities/ticket/graphql/queries/ticketWithMentionLimit.api.ts'

import { TicketLiveUserDeleteDocument } from '../../graphql/mutations/live-user/delete.api.ts'
import { TicketLiveUserUpsertDocument } from '../../graphql/mutations/live-user/ticketLiveUserUpsert.api.ts'

const ticketDate = new Date(2022, 0, 29, 0, 0, 0, 0)

export const defaultTicket = (
  policies: Partial<PolicyTicket> = {},
  preferences: Partial<any | null> = {},
  state: Partial<any> = {},
) => {
  initializeStore()

  return nullableMock<TicketWithMentionLimitQuery>({
    ticket: {
      __typename: 'Ticket',
      id: convertToGraphQLId('Ticket', 1),
      internalId: 1,
      number: '610001',
      title: 'Test Ticket View',
      createdAt: ticketDate.toISOString(),
      updatedAt: ticketDate.toISOString(),
      escalationAt: new Date(2022, 0, 29, 10, 0, 0, 0).toISOString(),
      pendingTime: null,
      subscribed: false,
      mentions: null,
      policy: {
        update: true,
        agentReadAccess: useSessionStore().hasPermission('ticket.agent'),
        ...policies,
      },
      createArticleType: {
        id: convertToGraphQLId('TicketArticleType', 5),
        name: 'email',
        __typename: 'TicketArticleType',
      },
      owner: {
        __typename: 'User',
        internalId: 100,
        id: convertToGraphQLId('User', 100),
        firstname: 'Max',
        lastname: 'Mustermann',
      },
      customer: {
        __typename: 'User',
        id: convertToGraphQLId('User', 200),
        internalId: 200,
        firstname: 'John',
        lastname: 'Doe',
        fullname: 'John Doe',
        active: true,
        policy: {
          __typename: 'PolicyDefault',
          update: true,
        },
      },
      organization: {
        __typename: 'Organization',
        id: convertToGraphQLId('Organization', 300),
        internalId: 300,
        name: 'Zammad Foundation',
        active: true,
        vip: true,
      },
      state: {
        __typename: 'TicketState',
        id: convertToGraphQLId('Ticket::State', 2),
        name: 'open',
        stateType: {
          __typename: 'TicketStateType',
          id: convertToGraphQLId('TicketStateType', 2),
          name: TicketState.Open,
        },
        ...state,
      },
      group: {
        __typename: 'Group',
        id: convertToGraphQLId('Group', 1),
        name: 'Users',
        emailAddress: {
          __typename: 'EmailAddressParsed',
          name: 'zammad',
          emailAddress: 'zammad@example.com',
        },
      },
      priority: {
        __typename: 'TicketPriority',
        id: convertToGraphQLId('Ticket::Priority', 1),
        name: '1 low',
        uiColor: 'low',
        defaultCreate: false,
      },
      objectAttributeValues: [],
      stateColorCode: EnumTicketStateColorCode.Open,
      preferences,
    },
  })
}

const address = {
  __typename: 'AddressesField' as const,
  parsed: null,
  raw: '',
}

export const defaultArticles = (): TicketArticlesQuery =>
  nullableMock({
    firstArticles: {
      __typename: 'TicketArticleConnection',
      edges: [
        {
          __typename: 'TicketArticleEdge',
          node: {
            __typename: 'TicketArticle',
            id: convertToGraphQLId('TicketArticle', 1),
            internalId: 1,
            createdAt: ticketDate.toISOString(),
            to: address,
            replyTo: address,
            cc: address,
            from: address,
            author: {
              __typename: 'User',
              id: 'fdsf214fse12d',
              firstname: 'John',
              lastname: 'Doe',
              fullname: 'John Doe',
              active: true,
              image: null,
              authorizations: [],
            },
            internal: false,
            bodyWithUrls: '<p>Body <b>of a test ticket</b></p>',
            sender: {
              __typename: 'TicketArticleSender',
              name: EnumTicketArticleSenderName.Customer,
            },
            type: {
              __typename: 'TicketArticleType',
              name: 'article',
            },
            contentType: 'text/html',
            attachmentsWithoutInline: [
              // should not be visible
              {
                __typename: 'StoredFile',
                id: convertToGraphQLId('Store', 66),
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
            __typename: 'TicketArticle',
            id: convertToGraphQLId('TicketArticle', 2),
            internalId: 2,
            to: address,
            replyTo: address,
            cc: address,
            from: address,
            createdAt: new Date(2022, 0, 30, 0, 0, 0, 0).toISOString(),
            author: {
              __typename: 'User',
              id: 'dsvvr32532fs',
              firstname: 'Albert',
              lastname: 'Einstein',
              fullname: 'Albert Einstein',
              active: true,
              image: null,
              authorizations: [],
            },
            internal: false,
            bodyWithUrls: '<p>energy equals power times time</p>',
            sender: {
              __typename: 'TicketArticleSender',
              name: EnumTicketArticleSenderName.Agent,
            },
            type: {
              __typename: 'TicketArticleType',
              name: 'article',
            },
            attachmentsWithoutInline: [],
            preferences: {},
            contentType: 'text/html',
          },
          cursor: 'MH',
        },
        {
          __typename: 'TicketArticleEdge',
          node: {
            __typename: 'TicketArticle',
            id: convertToGraphQLId('TicketArticle', 3),
            internalId: 3,
            to: address,
            replyTo: address,
            cc: address,
            from: address,
            createdAt: new Date(2022, 0, 30, 10, 0, 0, 0).toISOString(),
            author: {
              __typename: 'User',
              id: 'fsfy345343f',
              firstname: 'Monkey',
              lastname: 'Brain',
              fullname: 'Monkey Brain',
              active: true,
              image: null,
              authorizations: [],
            },
            internal: true,
            bodyWithUrls: '<p>only agents can see this haha</p>',
            sender: {
              __typename: 'TicketArticleSender',
              name: EnumTicketArticleSenderName.Agent,
            },
            type: {
              __typename: 'TicketArticleType',
              name: 'article',
            },
            contentType: 'text/html',
            attachmentsWithoutInline: [],
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

interface MockOptions {
  mockSubscription?: boolean
  mockFrontendObjectAttributes?: boolean
  ticket?: TicketQuery
  articles?: TicketArticlesQuery | TicketArticlesQuery[]
  ticketView?: TicketView
}

export const mockTicketLiveUsersGql = () => {
  const mockTicketLiveUsersSubscription = mockGraphQLSubscription(
    TicketLiveUserUpdatesDocument,
  )

  const mockTicketLiveUserUpsert = mockGraphQLApi(
    TicketLiveUserUpsertDocument,
  ).willResolve(
    nullableMock<TicketLiveUserUpsertPayload>({
      success: true,
      errors: null,
    }),
  )

  const mockTicketLiveUserDelete = mockGraphQLApi(
    TicketLiveUserDeleteDocument,
  ).willResolve(
    nullableMock<TicketLiveUserDeletePayload>({
      success: true,
      errors: null,
    }),
  )

  return {
    mockTicketLiveUsersSubscription,
    mockTicketLiveUserUpsert,
    mockTicketLiveUserDelete,
  }
}

export const mockTicketGql = (ticket: TicketQuery = defaultTicket()) => {
  const mockApiTicket = mockGraphQLApi(TicketDocument).willResolve(ticket)

  const waitUntilTicketLoaded = async () => {
    await waitUntil(() => mockApiTicket.calls.resolve)
  }

  return {
    mockApiTicket,
    waitUntilTicketLoaded,
  }
}

export const mockTicketDetailViewGql = (options: MockOptions = {}) => {
  const {
    mockSubscription = true,
    mockFrontendObjectAttributes = false,
    ticketView = 'agent',
  } = options

  setupView(ticketView)

  if (mockFrontendObjectAttributes) {
    mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willBehave(
      ({ object }) => {
        if (object === 'Ticket') {
          return {
            data: { objectManagerFrontendAttributes: ticketObjectAttributes() },
          }
        }
        return {
          data: {
            objectManagerFrontendAttributes: ticketArticleObjectAttributes(),
          },
        }
      },
    )
    mockGraphQLApi(FormUpdaterDocument).willResolve({
      formUpdater: {
        fields: {
          pending_time: {
            show: false,
          },
        },
      },
    })
  }

  const ticket = options.ticket || defaultTicket()

  const mockApiTicket = mockGraphQLApi(
    TicketWithMentionLimitDocument,
  ).willResolve(ticket)
  const mockApiArticles = mockGraphQLApi(TicketArticlesDocument).willResolve(
    options.articles || defaultArticles(),
  )
  let mockTicketSubscription: ExtendedIMockSubscription
  if (mockSubscription) {
    mockTicketSubscription = mockGraphQLSubscription(TicketUpdatesDocument)
  } else {
    mockTicketSubscription = {} as ExtendedIMockSubscription
  }

  const mockTicketArticleSubscription = mockGraphQLSubscription(
    TicketArticleUpdatesDocument,
  )

  const waitUntilTicketLoaded = async () => {
    await waitUntil(
      () => mockApiTicket.calls.resolve && mockApiArticles.calls.resolve,
    )
  }

  const mockTicketLiveUser = mockTicketLiveUsersGql()

  const mockOnlineNotificationSeen = mockOnlineNotificationSeenGql()

  return {
    ticket: ticket.ticket,
    mockApiArticles,
    mockApiTicket,
    mockTicketSubscription,
    mockTicketArticleSubscription,
    waitUntilTicketLoaded,
    ...mockTicketLiveUser,
    ...mockOnlineNotificationSeen,
  }
}
