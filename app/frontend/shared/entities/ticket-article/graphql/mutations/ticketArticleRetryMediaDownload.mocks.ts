import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleRetryMediaDownload.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticleRetryMediaDownloadMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleRetryMediaDownloadDocument, defaults)
}

export function waitForTicketArticleRetryMediaDownloadMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleRetryMediaDownloadMutation>(Operations.TicketArticleRetryMediaDownloadDocument)
}

export function mockTicketArticleRetryMediaDownloadMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticleRetryMediaDownloadDocument, message, extensions);
}
