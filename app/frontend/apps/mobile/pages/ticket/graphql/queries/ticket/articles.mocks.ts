import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './articles.api.ts'

export function mockTicketArticlesQuery(defaults: Mocks.MockDefaultsValue<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticlesDocument, defaults)
}

export function waitForTicketArticlesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticlesQuery>(Operations.TicketArticlesDocument)
}
