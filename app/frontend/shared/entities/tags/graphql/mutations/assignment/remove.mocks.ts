import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './remove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTagAssignmentRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TagAssignmentRemoveMutation, Types.TagAssignmentRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TagAssignmentRemoveDocument, defaults)
}

export function waitForTagAssignmentRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TagAssignmentRemoveMutation>(Operations.TagAssignmentRemoveDocument)
}

export function mockTagAssignmentRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TagAssignmentRemoveDocument, message, extensions);
}
