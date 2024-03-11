import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleRetryMediaDownload.api.ts'

export function mockTicketArticleRetryMediaDownloadMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleRetryMediaDownloadDocument, defaults)
}

export function waitForTicketArticleRetryMediaDownloadMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleRetryMediaDownloadMutation>(Operations.TicketArticleRetryMediaDownloadDocument)
}
