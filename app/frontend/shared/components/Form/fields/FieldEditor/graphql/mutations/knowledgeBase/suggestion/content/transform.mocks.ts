import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './transform.api.ts'

export function mockKnowledgeBaseAnswerSuggestionContentTransformMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation, Types.KnowledgeBaseAnswerSuggestionContentTransformMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerSuggestionContentTransformDocument, defaults)
}

export function waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerSuggestionContentTransformMutation>(Operations.KnowledgeBaseAnswerSuggestionContentTransformDocument)
}
