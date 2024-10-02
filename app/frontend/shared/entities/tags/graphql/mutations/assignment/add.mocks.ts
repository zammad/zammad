import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'

export function mockTagAssignmentAddMutation(defaults: Mocks.MockDefaultsValue<Types.TagAssignmentAddMutation, Types.TagAssignmentAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TagAssignmentAddDocument, defaults)
}

export function waitForTagAssignmentAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TagAssignmentAddMutation>(Operations.TagAssignmentAddDocument)
}
