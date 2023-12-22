import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './customerUpdate.api.ts'

export function mockTicketCustomerUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketCustomerUpdateMutation, Types.TicketCustomerUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketCustomerUpdateDocument, defaults)
}

export function waitForTicketCustomerUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketCustomerUpdateMutation>(Operations.TicketCustomerUpdateDocument)
}
