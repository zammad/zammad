import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './remove.api.ts'

export function mockTagAssignmentRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TagAssignmentRemoveMutation, Types.TagAssignmentRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TagAssignmentRemoveDocument, defaults)
}

export function waitForTagAssignmentRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TagAssignmentRemoveMutation>(Operations.TagAssignmentRemoveDocument)
}
