import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './merge.api.ts'

export function mockTicketMergeMutation(defaults: Mocks.MockDefaultsValue<Types.TicketMergeMutation, Types.TicketMergeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketMergeDocument, defaults)
}

export function waitForTicketMergeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketMergeMutation>(Operations.TicketMergeDocument)
}
