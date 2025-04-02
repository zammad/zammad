import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleRetrySecurityProcess.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleRetrySecurityProcessMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleRetrySecurityProcessDocument, defaults)
}

export function waitForTicketArticleRetrySecurityProcessMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleRetrySecurityProcessMutation>(Operations.TicketArticleRetrySecurityProcessDocument)
}

export function mockTicketArticleRetrySecurityProcessMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleRetrySecurityProcessDocument, message, extensions);
}
