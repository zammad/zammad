import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleTranslationTargetLocales.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleTranslationTargetLocalesQuery(defaults: Mocks.MockDefaultsValue<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleTranslationTargetLocalesDocument, defaults)
}

export function waitForTicketArticleTranslationTargetLocalesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleTranslationTargetLocalesQuery>(Operations.TicketArticleTranslationTargetLocalesDocument)
}

export function mockTicketArticleTranslationTargetLocalesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleTranslationTargetLocalesDocument, message, extensions);
}
