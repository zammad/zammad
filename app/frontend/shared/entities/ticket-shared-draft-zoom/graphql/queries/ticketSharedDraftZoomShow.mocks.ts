import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftZoomShow.api.ts'

export function mockTicketSharedDraftZoomShowQuery(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftZoomShowQuery, Types.TicketSharedDraftZoomShowQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftZoomShowDocument, defaults)
}

export function waitForTicketSharedDraftZoomShowQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftZoomShowQuery>(Operations.TicketSharedDraftZoomShowDocument)
}
