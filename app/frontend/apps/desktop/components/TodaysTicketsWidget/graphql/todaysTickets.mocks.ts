import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './todaysTickets.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export function mockTodaysTicketsQuery(
  defaults: Mocks.MockDefaultsValue<
    Operations.TodaysTicketsQuery,
    Operations.TodaysTicketsQueryVariables
  >,
) {
  return Mocks.mockGraphQLResult(Operations.TodaysTicketsDocument, defaults)
}

export function waitForTodaysTicketsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Operations.TodaysTicketsQuery>(
    Operations.TodaysTicketsDocument,
  )
}

export function mockTodaysTicketsQueryError(
  message: string,
  extensions: { type: ErrorTypes.GraphQLErrorTypes },
) {
  return Mocks.mockGraphQLResultWithError(Operations.TodaysTicketsDocument, message, extensions)
}

// Mock data sets for different test scenarios
export const createMockTicketForToday = (overrides = {}) => {
  return generateObjectData('Ticket', {
    id: convertToGraphQLId('Ticket', 1),
    internalId: 1,
    number: '53001',
    title: 'Test Ticket for Today',
    createdAt: new Date().toISOString(),
    stateColorCode: EnumTicketStateColorCode.Open,
    customer: {
      id: convertToGraphQLId('User', 2),
      internalId: 2,
      fullname: 'John Doe',
    },
    organization: {
      id: convertToGraphQLId('Organization', 1),
      internalId: 1,
      name: 'Example Organization',
    },
    group: {
      id: convertToGraphQLId('Group', 1),
      name: 'Support',
    },
    state: {
      id: convertToGraphQLId('Ticket::State', 2),
      name: 'open',
    },
    ...overrides,
  })
}

export const createMultipleMockTickets = (count = 3) => {
  return Array.from({ length: count }, (_, index) =>
    createMockTicketForToday({
      id: convertToGraphQLId('Ticket', index + 1),
      internalId: index + 1,
      number: `5300${index + 1}`,
      title: `Test Ticket ${index + 1}`,
      customer: {
        id: convertToGraphQLId('User', index + 2),
        internalId: index + 2,
        fullname: `Customer ${index + 1}`,
      },
    }),
  )
}

export const mockTodaysTicketsQueryWithLoading = () => {
  return mockTodaysTicketsQuery({
    todaysTickets: {
      __typename: 'TicketConnection',
      totalCount: 0,
      edges: [],
    },
  })
}

export const mockTodaysTicketsQueryWithEmptyData = () => {
  return mockTodaysTicketsQuery({
    todaysTickets: {
      totalCount: 0,
      edges: [],
    },
  })
}

export const mockTodaysTicketsQueryWithSingleTicket = (ticket = createMockTicketForToday()) => {
  return mockTodaysTicketsQuery({
    todaysTickets: {
      totalCount: 1,
      edges: [
        {
          node: ticket,
        },
      ],
    },
  })
}

export const mockTodaysTicketsQueryWithMultipleTickets = (
  tickets = createMultipleMockTickets(),
) => {
  return mockTodaysTicketsQuery({
    todaysTickets: {
      totalCount: tickets.length,
      edges: tickets.map((ticket) => ({
        node: ticket,
      })),
    },
  })
}

// Error scenario helpers
export const mockTodaysTicketsQueryWithNetworkError = () => {
  return mockTodaysTicketsQueryError('Error loading tickets. Please try again later.', {
    type: ErrorTypes.GraphQLErrorTypes.NetworkError,
  })
}

export const mockTodaysTicketsQueryWithGenericError = (message = 'Something went wrong') => {
  return mockTodaysTicketsQueryError(message, { type: ErrorTypes.GraphQLErrorTypes.UnknownError })
}
