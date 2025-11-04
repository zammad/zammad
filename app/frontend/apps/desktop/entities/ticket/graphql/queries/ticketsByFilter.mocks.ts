import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsByFilter.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsByFilterQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsByFilterQuery, Types.TicketsByFilterQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsByFilterDocument, defaults)
}

export function waitForTicketsByFilterQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsByFilterQuery>(Operations.TicketsByFilterDocument)
}

export function mockTicketsByFilterQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsByFilterDocument, message, extensions);
}
