import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerVisibilityScheduleAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerVisibilityScheduleAddMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerVisibilityScheduleAddMutation, Types.KnowledgeBaseAnswerVisibilityScheduleAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerVisibilityScheduleAddDocument, defaults)
}

export function waitForKnowledgeBaseAnswerVisibilityScheduleAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerVisibilityScheduleAddMutation>(Operations.KnowledgeBaseAnswerVisibilityScheduleAddDocument)
}

export function mockKnowledgeBaseAnswerVisibilityScheduleAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerVisibilityScheduleAddDocument, message, extensions);
}
