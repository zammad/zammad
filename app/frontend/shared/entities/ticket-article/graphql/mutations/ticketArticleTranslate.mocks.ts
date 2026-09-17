import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleTranslate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleTranslateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleTranslateDocument, defaults)
}

export function waitForTicketArticleTranslateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleTranslateMutation>(Operations.TicketArticleTranslateDocument)
}

export function mockTicketArticleTranslateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleTranslateDocument, message, extensions);
}
