import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartSingle.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftStartSingleQuery(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartSingleDocument, defaults)
}

export function waitForTicketSharedDraftStartSingleQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartSingleQuery>(Operations.TicketSharedDraftStartSingleDocument)
}

export function mockTicketSharedDraftStartSingleQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftStartSingleDocument, message, extensions);
}
