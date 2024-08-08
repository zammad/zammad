import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistItemUpsert.api.ts'

export function mockTicketChecklistItemUpsertMutation(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistItemUpsertMutation, Types.TicketChecklistItemUpsertMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistItemUpsertDocument, defaults)
}

export function waitForTicketChecklistItemUpsertMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistItemUpsertMutation>(Operations.TicketChecklistItemUpsertDocument)
}
