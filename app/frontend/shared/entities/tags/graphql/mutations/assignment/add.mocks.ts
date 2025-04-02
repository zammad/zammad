import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTagAssignmentAddMutation(defaults: Mocks.MockDefaultsValue<Types.TagAssignmentAddMutation, Types.TagAssignmentAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TagAssignmentAddDocument, defaults)
}

export function waitForTagAssignmentAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TagAssignmentAddMutation>(Operations.TagAssignmentAddDocument)
}

export function mockTagAssignmentAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TagAssignmentAddDocument, message, extensions);
}
