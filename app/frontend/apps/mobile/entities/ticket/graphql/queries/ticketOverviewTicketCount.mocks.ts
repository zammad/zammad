import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketOverviewTicketCount.api.ts'

export function mockTicketOverviewTicketCountQuery(defaults: Mocks.MockDefaultsValue<Types.TicketOverviewTicketCountQuery, Types.TicketOverviewTicketCountQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketOverviewTicketCountDocument, defaults)
}

export function waitForTicketOverviewTicketCountQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketOverviewTicketCountQuery>(Operations.TicketOverviewTicketCountDocument)
}
