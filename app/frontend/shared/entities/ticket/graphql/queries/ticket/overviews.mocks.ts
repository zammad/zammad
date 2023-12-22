import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './overviews.api.ts'

export function mockTicketOverviewsQuery(defaults: Mocks.MockDefaultsValue<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketOverviewsDocument, defaults)
}

export function waitForTicketOverviewsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketOverviewsQuery>(Operations.TicketOverviewsDocument)
}
