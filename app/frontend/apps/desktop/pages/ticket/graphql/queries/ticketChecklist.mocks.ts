import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklist.api.ts'

export function mockTicketChecklistQuery(defaults: Mocks.MockDefaultsValue<Types.TicketChecklistQuery, Types.TicketChecklistQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketChecklistDocument, defaults)
}

export function waitForTicketChecklistQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketChecklistQuery>(Operations.TicketChecklistDocument)
}
