import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './customerUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketCustomerUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketCustomerUpdateDocument, defaults)
}

export function waitForTicketCustomerUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketCustomerUpdateMutation>(Operations.TicketCustomerUpdateDocument)
}

export function mockTicketCustomerUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketCustomerUpdateDocument, message, extensions);
}
