import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerVisibilityScheduleRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerVisibilityScheduleRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutation, Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerVisibilityScheduleRemoveDocument, defaults)
}

export function waitForKnowledgeBaseAnswerVisibilityScheduleRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutation>(Operations.KnowledgeBaseAnswerVisibilityScheduleRemoveDocument)
}

export function mockKnowledgeBaseAnswerVisibilityScheduleRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerVisibilityScheduleRemoveDocument, message, extensions);
}
