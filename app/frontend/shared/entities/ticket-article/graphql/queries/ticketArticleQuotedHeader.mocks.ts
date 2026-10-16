import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleQuotedHeader.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleQuotedHeaderQuery(defaults: Mocks.MockDefaultsValue<Types.TicketArticleQuotedHeaderQuery, Types.TicketArticleQuotedHeaderQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleQuotedHeaderDocument, defaults)
}

export function waitForTicketArticleQuotedHeaderQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleQuotedHeaderQuery>(Operations.TicketArticleQuotedHeaderDocument)
}

export function mockTicketArticleQuotedHeaderQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleQuotedHeaderDocument, message, extensions);
}
