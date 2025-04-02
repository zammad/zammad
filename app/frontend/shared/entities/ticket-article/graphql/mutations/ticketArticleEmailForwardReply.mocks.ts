import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleEmailForwardReply.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleEmailForwardReplyMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleEmailForwardReplyMutation, Types.TicketArticleEmailForwardReplyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleEmailForwardReplyDocument, defaults)
}

export function waitForTicketArticleEmailForwardReplyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleEmailForwardReplyMutation>(Operations.TicketArticleEmailForwardReplyDocument)
}

export function mockTicketArticleEmailForwardReplyMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleEmailForwardReplyDocument, message, extensions);
}
