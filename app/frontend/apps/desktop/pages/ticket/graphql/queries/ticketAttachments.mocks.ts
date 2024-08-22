import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketAttachments.api.ts'

export function mockTicketAttachmentsQuery(defaults: Mocks.MockDefaultsValue<Types.TicketAttachmentsQuery, Types.TicketAttachmentsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketAttachmentsDocument, defaults)
}

export function waitForTicketAttachmentsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketAttachmentsQuery>(Operations.TicketAttachmentsDocument)
}
