import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistItemOrderUpdate.api.ts'

export function mockTicketChecklistItemOrderUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistItemOrderUpdateMutation, Types.TicketChecklistItemOrderUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistItemOrderUpdateDocument, defaults)
}

export function waitForTicketChecklistItemOrderUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistItemOrderUpdateMutation>(Operations.TicketChecklistItemOrderUpdateDocument)
}
