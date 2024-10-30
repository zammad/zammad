import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './linkRemove.api.ts'

export function mockLinkRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.LinkRemoveDocument, defaults)
}

export function waitForLinkRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LinkRemoveMutation>(Operations.LinkRemoveDocument)
}
