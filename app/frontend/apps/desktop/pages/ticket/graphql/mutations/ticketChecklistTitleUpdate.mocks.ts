import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistTitleUpdate.api.ts'

export function mockTicketChecklistTitleUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistTitleUpdateMutation, Types.TicketChecklistTitleUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistTitleUpdateDocument, defaults)
}

export function waitForTicketChecklistTitleUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistTitleUpdateMutation>(Operations.TicketChecklistTitleUpdateDocument)
}
