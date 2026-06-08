import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './highlightedTextUpsert.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleHighlightedTextUpsertMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleHighlightedTextUpsertDocument, defaults)
}

export function waitForTicketArticleHighlightedTextUpsertMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleHighlightedTextUpsertMutation>(Operations.TicketArticleHighlightedTextUpsertDocument)
}

export function mockTicketArticleHighlightedTextUpsertMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleHighlightedTextUpsertDocument, message, extensions);
}
