import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticket.api.ts'

export function mockTicketQuery(defaults: Mocks.MockDefaultsValue<Types.TicketQuery, Types.TicketQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketDocument, defaults)
}

export function waitForTicketQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketQuery>(Operations.TicketDocument)
}
