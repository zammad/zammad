import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticket.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketQuery(defaults: Mocks.MockDefaultsValue<Types.TicketQuery, Types.TicketQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketDocument, defaults)
}

export function waitForTicketQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketQuery>(Operations.TicketDocument)
}

export function mockTicketQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketDocument, message, extensions);
}
