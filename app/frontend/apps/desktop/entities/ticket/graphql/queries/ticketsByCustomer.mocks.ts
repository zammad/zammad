import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsByCustomer.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsByCustomerQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsByCustomerQuery, Types.TicketsByCustomerQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsByCustomerDocument, defaults)
}

export function waitForTicketsByCustomerQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsByCustomerQuery>(Operations.TicketsByCustomerDocument)
}

export function mockTicketsByCustomerQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsByCustomerDocument, message, extensions);
}
