import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftStartListQuery(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartListDocument, defaults)
}

export function waitForTicketSharedDraftStartListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartListQuery>(Operations.TicketSharedDraftStartListDocument)
}

export function mockTicketSharedDraftStartListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftStartListDocument, message, extensions);
}
