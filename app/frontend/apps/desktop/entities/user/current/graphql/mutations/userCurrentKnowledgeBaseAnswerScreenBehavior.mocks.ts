import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentKnowledgeBaseAnswerScreenBehavior.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentKnowledgeBaseAnswerScreenBehaviorMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutation, Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentKnowledgeBaseAnswerScreenBehaviorDocument, defaults)
}

export function waitForUserCurrentKnowledgeBaseAnswerScreenBehaviorMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutation>(Operations.UserCurrentKnowledgeBaseAnswerScreenBehaviorDocument)
}

export function mockUserCurrentKnowledgeBaseAnswerScreenBehaviorMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentKnowledgeBaseAnswerScreenBehaviorDocument, message, extensions);
}
