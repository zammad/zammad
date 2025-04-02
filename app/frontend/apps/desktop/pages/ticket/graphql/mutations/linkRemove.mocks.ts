import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './linkRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockLinkRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.LinkRemoveDocument, defaults)
}

export function waitForLinkRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LinkRemoveMutation>(Operations.LinkRemoveDocument)
}

export function mockLinkRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.LinkRemoveDocument, message, extensions);
}
