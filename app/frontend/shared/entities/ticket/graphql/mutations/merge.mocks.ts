import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './merge.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketMergeMutation(defaults: Mocks.MockDefaultsValue<Types.TicketMergeMutation, Types.TicketMergeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketMergeDocument, defaults)
}

export function waitForTicketMergeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketMergeMutation>(Operations.TicketMergeDocument)
}

export function mockTicketMergeMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketMergeDocument, message, extensions);
}
