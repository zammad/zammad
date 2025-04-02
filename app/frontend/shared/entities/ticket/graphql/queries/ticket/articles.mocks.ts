import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './articles.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticlesQuery(defaults: Mocks.MockDefaultsValue<Types.TicketArticlesQuery, Types.TicketArticlesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticlesDocument, defaults)
}

export function waitForTicketArticlesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticlesQuery>(Operations.TicketArticlesDocument)
}

export function mockTicketArticlesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticlesDocument, message, extensions);
}
