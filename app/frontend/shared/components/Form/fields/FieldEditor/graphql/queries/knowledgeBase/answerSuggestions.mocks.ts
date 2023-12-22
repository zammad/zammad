import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './answerSuggestions.api.ts'

export function mockKnowledgeBaseAnswerSuggestionsQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerSuggestionsQuery, Types.KnowledgeBaseAnswerSuggestionsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerSuggestionsDocument, defaults)
}

export function waitForKnowledgeBaseAnswerSuggestionsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerSuggestionsQuery>(Operations.KnowledgeBaseAnswerSuggestionsDocument)
}
