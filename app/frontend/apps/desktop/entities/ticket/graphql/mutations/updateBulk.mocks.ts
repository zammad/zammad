import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './updateBulk.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketUpdateBulkMutation(defaults: Mocks.MockDefaultsValue<Types.TicketUpdateBulkMutation, Types.TicketUpdateBulkMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketUpdateBulkDocument, defaults)
}

export function waitForTicketUpdateBulkMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketUpdateBulkMutation>(Operations.TicketUpdateBulkDocument)
}

export function mockTicketUpdateBulkMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketUpdateBulkDocument, message, extensions);
}
