import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './transform.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerSuggestionContentTransformMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerSuggestionContentTransformDocument, defaults)
}

export function waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation>(Operations.KnowledgeBaseAnswerSuggestionContentTransformDocument)
}

export function mockKnowledgeBaseAnswerSuggestionContentTransformMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerSuggestionContentTransformDocument, message, extensions);
}
