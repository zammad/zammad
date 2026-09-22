import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleTranslateMany.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleTranslateManyMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleTranslateManyDocument, defaults)
}

export function waitForTicketArticleTranslateManyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleTranslateManyMutation>(Operations.TicketArticleTranslateManyDocument)
}

export function mockTicketArticleTranslateManyMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleTranslateManyDocument, message, extensions);
}
